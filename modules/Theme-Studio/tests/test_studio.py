"""Run with python3 -m unittest discover -s modules/Theme_Studio/tests -v."""
import io
import json
import os
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from studio import (ACCENTS, BACKGROUND, GNOME_SHELL, INTERFACE, SHELL, USER_THEME_UUID,
                    Settings, Studio, StudioError,
                    atomic_json, catalog, extract_archive, looks, quote)


class FakeSettings:
    def __init__(self):
        self.values = {(INTERFACE, 'gtk-theme'): quote('Adwaita'),
                       (INTERFACE, 'icon-theme'): quote('Adwaita'),
                       (INTERFACE, 'cursor-theme'): quote('Adwaita'),
                       (INTERFACE, 'color-scheme'): quote('default'),
                       (INTERFACE, 'accent-color'): quote('blue'),
                       (BACKGROUND, 'picture-uri'): quote('file:///original.png'),
                       (BACKGROUND, 'picture-uri-dark'): quote('file:///original.png'),
                       (BACKGROUND, 'picture-options'): quote('zoom'),
                       (GNOME_SHELL, 'disable-user-extensions'): False,
                       (GNOME_SHELL, 'enabled-extensions'): [],
                       (SHELL, 'name'): quote('')}
        self.defaults = self.values.copy()
        self.fail_once = None
        self.writes = []

    def has(self, schema, key):
        return (schema, key) in self.values

    def get(self, schema, key):
        return self.values[schema, key]

    def check(self, schema, key, value):
        if not self.has(schema, key):
            raise StudioError('Unavailable key')

    def set(self, schema, key, value):
        self.check(schema, key, value)
        if self.fail_once == key:
            self.fail_once = None
            raise StudioError('Injected write failure')
        self.values[schema, key] = value
        self.writes.append((schema, key, value))

    def default(self, schema, key):
        return self.defaults[schema, key]

    def get_boolean(self, schema, key):
        return self.values[schema, key]

    def set_boolean(self, schema, key, value):
        self.values[schema, key] = value

    def get_strv(self, schema, key):
        return list(self.values[schema, key])

    def set_strv(self, schema, key, values):
        self.values[schema, key] = list(values)


class StudioTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.env = patch.dict(os.environ, {k: str(self.home / v) for k, v in [
            ('XDG_DATA_HOME', '.local/share'), ('XDG_CONFIG_HOME', '.config'), ('XDG_STATE_HOME', '.local/state')]})
        self.env.start()
        self.settings = FakeSettings()
        self.studio = Studio(self.home, self.settings)

    def tearDown(self):
        self.env.stop()
        self.temp.cleanup()

    def theme(self, name='Test Theme', gtk4=True):
        path = self.studio.data / 'themes' / name
        (path / 'gtk-3.0').mkdir(parents=True)
        (path / 'gtk-3.0/gtk.css').write_text('/* theme */')
        if gtk4:
            (path / 'gtk-4.0').mkdir()
            (path / 'gtk-4.0/gtk.css').write_text('/* gtk4 */')
        return path

    def test_catalog_pinned_and_unique(self):
        entries = catalog()
        self.assertEqual(len(entries), 33)
        self.assertEqual(len({e['id'] for e in entries}), 33)
        self.assertEqual(sum(e['kind'] == 'theme' for e in entries), 16)
        self.assertEqual(sum(e['kind'] == 'icons' for e in entries), 17)
        for entry in entries:
            self.assertRegex(entry['revision'], r'^[0-9a-f]{40}$')
            self.assertRegex(entry['repository'], r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')

    def test_looks_have_thirty_distinct_4k_wallpapers(self):
        self.assertEqual(len(looks()), 30)
        bodies = {self.studio.wallpaper(look).read_text() for look in looks()}
        self.assertEqual(len(bodies), 30)
        for body in bodies:
            self.assertIn('width="3840" height="2160"', body)
        ids = {x['id'] for x in catalog()}
        for look in looks():
            self.assertIn(look['theme_family'], ids)
            self.assertIn(look['icon_family'], ids)
            self.assertIn(look['accent'], ACCENTS)

    def test_apply_and_undo(self):
        before = self.settings.values.copy()
        self.studio.apply(mode='dark', accent='purple')
        self.assertEqual(self.settings.values[INTERFACE, 'color-scheme'], quote('prefer-dark'))
        self.studio.recover(undo=True)
        self.assertEqual(self.settings.values, before)

    def test_failed_write_rolls_back_all_previous_writes(self):
        before = self.settings.values.copy()
        self.settings.fail_once = 'accent-color'
        with self.assertRaisesRegex(StudioError, 'rolled back'):
            self.studio.apply(mode='dark', accent='purple')
        self.assertEqual(self.settings.values, before)
        self.assertFalse((self.studio.state / 'pending.json').exists())

    def test_invalid_theme_does_not_write(self):
        with self.assertRaisesRegex(StudioError, 'Install the gtk'):
            self.studio.apply(gtk='does-not-exist', mode='dark')
        self.assertEqual(self.settings.writes, [])

    def test_unsupported_accent_fails_before_writes(self):
        del self.settings.values[INTERFACE, 'accent-color']
        with self.assertRaisesRegex(StudioError, 'GNOME 47'):
            self.studio.apply(mode='dark', accent='blue')
        self.assertEqual(self.settings.writes, [])

    def test_shell_extension_is_enabled_without_losing_existing_extensions(self):
        existing = 'example@extensions.test'
        self.settings.values[GNOME_SHELL, 'disable-user-extensions'] = True
        self.settings.values[GNOME_SHELL, 'enabled-extensions'] = [existing]
        commands = []

        def extension_command(argv, **_kwargs):
            commands.append(argv)
            if argv == ['gnome-extensions', 'list']:
                return USER_THEME_UUID + '\n'
            if argv == ['gnome-extensions', 'list', '--active']:
                return USER_THEME_UUID + '\n'
            return ''

        with patch('studio.shutil.which', return_value='/usr/bin/gnome-extensions'), patch('studio.run', side_effect=extension_command):
            self.studio.check_shell()
        self.assertFalse(self.settings.values[GNOME_SHELL, 'disable-user-extensions'])
        self.assertEqual(self.settings.values[GNOME_SHELL, 'enabled-extensions'], [existing, USER_THEME_UUID])
        self.assertIn(['gnome-extensions', 'enable', USER_THEME_UUID], commands)

    def test_shell_extension_queues_enable_when_current_shell_needs_login(self):
        self.settings.values[GNOME_SHELL, 'enabled-extensions'] = []

        def extension_command(argv, **_kwargs):
            if argv == ['gnome-extensions', 'list']:
                return USER_THEME_UUID + '\n'
            return ''

        with patch('studio.shutil.which', return_value='/usr/bin/gnome-extensions'), patch('studio.run', side_effect=extension_command):
            with self.assertRaisesRegex(StudioError, 'Log out and back in once'):
                self.studio.check_shell()
        self.assertEqual(self.settings.values[GNOME_SHELL, 'enabled-extensions'], [USER_THEME_UUID])

    def test_invalid_accent_and_mode(self):
        for args in ({'mode': 'oops'}, {'accent': 'oops'}):
            with self.assertRaises(StudioError):
                self.studio.apply(**args)
        self.assertEqual(self.settings.writes, [])

    def test_gtk4_apply_reset_restores_original(self):
        theme = self.theme()
        target = self.studio.config / 'gtk-4.0'
        target.mkdir(parents=True)
        (target / 'gtk.css').write_text('original custom CSS')
        (target / 'settings.ini').write_text('user settings')
        self.studio.apply(gtk=theme.name, gtk4=True)
        self.assertIn(theme.as_uri(), (target / 'gtk.css').read_text())
        self.studio.reset()
        self.assertEqual((target / 'gtk.css').read_text(), 'original custom CSS')
        self.assertEqual((target / 'settings.ini').read_text(), 'user settings')
        self.assertFalse((target / 'gtk-dark.css').exists())
        self.studio.recover(undo=True)
        self.assertIn(theme.as_uri(), (target / 'gtk.css').read_text())

    def test_gtk4_failure_restores_user_files(self):
        theme = self.theme()
        target = self.studio.config / 'gtk-4.0'
        target.mkdir(parents=True)
        (target / 'gtk.css').write_text('original')
        self.settings.fail_once = 'gtk-theme'
        with self.assertRaises(StudioError):
            self.studio.apply(gtk=theme.name, gtk4=True)
        self.assertEqual((target / 'gtk.css').read_text(), 'original')

    def test_missing_gtk4_does_not_apply_gtk3(self):
        theme = self.theme(gtk4=False)
        with self.assertRaisesRegex(StudioError, 'does not provide GTK4'):
            self.studio.apply(gtk=theme.name, gtk4=True)
        self.assertEqual(self.settings.writes, [])

    def test_gtk4_directory_symlink_refused(self):
        theme = self.theme()
        elsewhere = self.home / 'elsewhere'
        elsewhere.mkdir()
        self.studio.config.mkdir()
        (self.studio.config / 'gtk-4.0').symlink_to(elsewhere)
        with self.assertRaisesRegex(StudioError, 'symlink'):
            self.studio.apply(gtk=theme.name, gtk4=True)

    def test_individual_css_symlink_does_not_write_target(self):
        theme = self.theme()
        target = self.studio.config / 'gtk-4.0'
        target.mkdir(parents=True)
        original = self.home / 'personal.css'
        original.write_text('original')
        (target / 'gtk.css').symlink_to(original)
        self.studio.apply(gtk=theme.name, gtk4=True)
        self.assertEqual(original.read_text(), 'original')
        self.studio.recover(undo=True)
        self.assertTrue((target / 'gtk.css').is_symlink())

    def test_pending_recovery_blocks_new_transaction(self):
        changes = [(INTERFACE, 'color-scheme', quote('prefer-dark'))]
        folder = self.studio.snapshot(changes)
        atomic_json(self.studio.state / 'pending.json', {'snapshot': folder.name})
        self.settings.set(*changes[0])
        with self.assertRaisesRegex(StudioError, 'interrupted'):
            self.studio.apply(mode='light')
        with self.assertRaisesRegex(StudioError, 'interrupted'):
            self.studio.recover(undo=True)
        self.studio.recover()
        self.assertEqual(self.settings.get(INTERFACE, 'color-scheme'), quote('default'))

    def test_concurrent_mutation_refused(self):
        with self.studio.lock():
            with self.assertRaisesRegex(StudioError, 'Another Theme Studio'):
                self.studio.apply(mode='dark')

    def test_uninstall_protects_active_family(self):
        theme = self.theme()
        atomic_json(self.studio.state / 'installed.json', {'test': {'paths': [str(theme)]}})
        self.studio.apply(gtk=theme.name)
        with self.assertRaisesRegex(StudioError, 'active'):
            self.studio.uninstall('test')
        self.assertTrue(theme.exists())
        self.studio.reset()
        self.studio.uninstall('test')
        self.assertFalse(theme.exists())

    def test_uninstall_refuses_unmanaged_and_malicious_paths(self):
        with self.assertRaises(StudioError):
            self.studio.uninstall('not-managed')
        atomic_json(self.studio.state / 'installed.json', {'test': {'paths': [str(self.home)]}})
        with self.assertRaisesRegex(StudioError, 'Invalid managed'):
            self.studio.uninstall('test')
        self.assertTrue(self.home.exists())

    def test_uninstall_protects_gtk4_reference(self):
        theme = self.theme()
        atomic_json(self.studio.state / 'installed.json', {'test': {'paths': [str(theme)]}})
        self.studio.apply(gtk=theme.name, gtk4=True)
        self.settings.set(INTERFACE, 'gtk-theme', quote('Adwaita'))
        with self.assertRaisesRegex(StudioError, 'GTK4 styling'):
            self.studio.uninstall('test')

    def test_symlinked_data_outside_home_refused(self):
        with tempfile.TemporaryDirectory() as other:
            (self.home / 'linked').symlink_to(other)
            with patch.dict(os.environ, {'XDG_DATA_HOME': str(self.home / 'linked')}):
                with self.assertRaisesRegex(StudioError, 'inside your home'):
                    Studio(self.home)

    def test_corrupt_state_is_not_silently_overwritten(self):
        self.studio.state.mkdir(parents=True)
        (self.studio.state / 'installed.json').write_text('{broken')
        with self.assertRaisesRegex(StudioError, 'Cannot read'):
            self.studio.registry()

    def test_wallpaper_uri_escapes_spaces_and_quotes(self):
        path = self.home / "my wallpaper's.png"
        path.write_bytes(b'placeholder')
        self.studio.apply(wallpaper=path)
        value = self.settings.get(BACKGROUND, 'picture-uri')
        self.assertIn('%20', value)
        self.assertIn('%27', value)
        self.assertEqual(value, self.settings.get(BACKGROUND, 'picture-uri-dark'))

    def test_save_and_apply_custom_look(self):
        self.studio.save_look('my-desktop')
        saved = json.loads((self.studio.assets / 'looks.json').read_text())
        self.assertEqual(saved['my-desktop']['settings']['gtk'], 'Adwaita')
        with self.assertRaises(StudioError):
            self.studio.save_look('../escape')
        with self.assertRaises(StudioError):
            self.studio.save_look('aurora-light')

    def test_app_launcher(self):
        self.studio.add_launcher()
        content = (self.studio.data / 'applications/rtd-theme-studio.desktop').read_text()
        self.assertIn('Type=Application', content)
        self.assertIn('rtd-theme-studio"', content)


class ArchiveTests(unittest.TestCase):
    def archive(self, entries):
        file = io.BytesIO()
        with tarfile.open(fileobj=file, mode='w') as archive:
            for name, value, kind in entries:
                info = tarfile.TarInfo(name)
                if kind == 'file':
                    data = value.encode()
                    info.size = len(data)
                    archive.addfile(info, io.BytesIO(data))
                else:
                    info.type = tarfile.SYMTYPE if kind == 'link' else tarfile.FIFOTYPE
                    info.linkname = value
                    archive.addfile(info)
        file.seek(0)
        return file

    def extract(self, entries):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            archive = path / 'source.tar'
            archive.write_bytes(self.archive(entries).read())
            target = path / 'target'
            target.mkdir()
            extract_archive(archive, target)
            return [(p.relative_to(target).as_posix(), p.read_text()) for p in target.rglob('*') if p.is_file()]

    def test_regular_file_and_safe_symlink(self):
        result = self.extract([('root/a', 'hello', 'file'), ('root/b', 'a', 'link')])
        self.assertEqual(sorted(result), [('root/a', 'hello'), ('root/b', 'hello')])

    def test_traversal_absolute_external_symlink_and_fifo(self):
        for entry in [('../escape', '', 'file'), ('/tmp/escape', '', 'file'),
                      ('root/link', '../../escape', 'link'), ('root/link', '/etc/passwd', 'link'),
                      ('root/fifo', '', 'fifo')]:
            with self.subTest(entry=entry), self.assertRaises(StudioError):
                self.extract([entry])

    def test_symlink_chain_escape(self):
        with self.assertRaises(StudioError):
            self.extract([('root/a', '..', 'link'), ('root/b', 'a/../outside', 'link')])

    def test_duplicate_file_refused(self):
        with self.assertRaises(FileExistsError):
            self.extract([('root/a', 'one', 'file'), ('root/a', 'two', 'file')])



class ImportTests(unittest.TestCase):
    setUp = StudioTests.setUp
    tearDown = StudioTests.tearDown
    theme = StudioTests.theme

    def fixture(self):
        return ArchiveTests().archive([
            ('source/Test/gtk-3.0/gtk.css', 'theme', 'file'),
            ('source/Test/gtk-4.0/gtk.css', 'theme4', 'file'),
            ('source/LICENSE', 'upstream license', 'file')])

    def entry(self):
        return dict(id='test', name='Test', kind='theme', method='copy',
                    repository='example/theme', revision='a' * 40, profiles={'default': []})

    def test_import_registers_and_preserves_notice(self):
        with patch('studio.catalog', return_value=[self.entry()]), patch('studio.urllib.request.urlopen', return_value=self.fixture()):
            self.studio.install('test')
        registry = self.studio.registry()['test']
        self.assertEqual(len(registry['paths']), 1)
        self.assertRegex(registry['sha256'], '^[0-9a-f]{64}$')
        self.assertEqual((self.studio.assets / 'sources/test/LICENSE').read_text(), 'upstream license')
        self.assertTrue((self.studio.data / 'themes/Test/gtk-3.0/gtk.css').exists())

    def test_import_will_not_overwrite_existing_theme(self):
        theme = self.theme('Test')
        with patch('studio.catalog', return_value=[self.entry()]), patch('studio.urllib.request.urlopen', return_value=self.fixture()):
            with self.assertRaisesRegex(StudioError, 'overwrite'):
                self.studio.install('test')
        self.assertEqual((theme / 'gtk-3.0/gtk.css').read_text(), '/* theme */')
        self.assertEqual(self.studio.registry(), {})

    def test_import_rolls_back_copy_failure(self):
        with patch('studio.catalog', return_value=[self.entry()]), patch('studio.urllib.request.urlopen', return_value=self.fixture()), patch('studio.copy_assets', side_effect=OSError('disk full')):
            with self.assertRaisesRegex(OSError, 'disk full'):
                self.studio.install('test')
        self.assertEqual(self.studio.registry(), {})
        self.assertFalse((self.studio.data / 'themes/Test').exists())

    def test_invalid_build_profile_never_downloads(self):
        with patch('studio.catalog', return_value=[self.entry()]), patch('studio.urllib.request.urlopen') as download:
            with self.assertRaisesRegex(StudioError, 'Unsupported build profile'):
                self.studio.install('test', '--evil')
            download.assert_not_called()

    def test_theme_install_refuses_root_before_download(self):
        with patch('studio.os.geteuid', return_value=0), patch('studio.urllib.request.urlopen') as download:
            with self.assertRaisesRegex(StudioError, 'administrator privileges'):
                self.studio.install('test')
            download.assert_not_called()

    def test_source_build_has_safe_terminal_environment(self):
        source = self.home / 'source'
        output = self.home / 'output'
        source.mkdir()
        output.mkdir()
        (source / 'install.sh').write_text('#!/usr/bin/env bash\n')
        entry = {'requires': [], 'profiles': {'default': []}}
        with patch('studio.shutil.which', return_value='/usr/bin/bwrap'), \
                patch('studio.run') as execute, patch('studio.normalize_build_links'):
            self.studio.build(source, output, entry)
        command = execute.call_args.args[0]
        term = command.index('TERM')
        self.assertEqual(command[term - 1:term + 2], ['--setenv', 'TERM', 'dumb'])

    def test_installed_family_reuse_and_missing_asset_repair_error(self):
        with patch('studio.catalog', return_value=[self.entry()]), patch('studio.urllib.request.urlopen', return_value=self.fixture()) as download:
            self.studio.install('test')
            self.assertIn('Already installed', self.studio.install('test'))
            self.assertEqual(download.call_count, 1)
            import shutil
            shutil.rmtree(self.studio.data / 'themes/Test')
            with self.assertRaisesRegex(StudioError, 'missing'):
                self.studio.install('test')

    def test_copy_preserves_internal_links_and_omits_dangling(self):
        from studio import copy_assets
        source = self.home / 'source'
        source.mkdir()
        (source / 'actual').write_text('icon')
        (source / 'alias').symlink_to('actual')
        (source / 'missing').symlink_to('absent')
        target = self.home / 'installed'
        count = copy_assets(source, target, self.home, 'icons')
        self.assertEqual(count, 1)
        self.assertTrue((target / 'alias').is_symlink())
        self.assertEqual((target / 'alias').read_text(), 'icon')
        self.assertFalse((target / 'missing').is_symlink())

    def test_copy_rejects_external_link(self):
        from studio import copy_assets
        source = self.home / 'source'
        source.mkdir()
        (source / 'external').symlink_to('/etc/passwd')
        with self.assertRaisesRegex(StudioError, 'External'):
            copy_assets(source, self.home / 'installed', self.home, 'icons')

    def test_copy_rejects_directory_cycle(self):
        from studio import copy_assets
        source = self.home / 'source'
        source.mkdir()
        (source / 'loop').symlink_to('.')
        with self.assertRaisesRegex(StudioError, 'Cyclic'):
            copy_assets(source, self.home / 'installed', self.home, 'icons')

    def test_look_installs_dependencies_and_applies_matching_variant(self):
        theme = self.theme('Example-Dark')
        icons = self.studio.data / 'icons/Example'
        icons.mkdir(parents=True)
        (icons / 'index.theme').write_text('[Icon Theme]\nName=Example\n')
        registry = {'orchis': {'paths': [str(theme)]}, 'tela-circle': {'paths': [str(icons)]}}
        with patch.object(self.studio, 'registry', return_value=registry), patch.object(self.studio, 'check_shell'), patch.object(self.studio, 'install') as install:
            self.studio.apply_look('aurora-dark')
            self.assertEqual([call.args[0] for call in install.call_args_list], ['orchis', 'tela-circle'])
        self.assertEqual(self.settings.get(INTERFACE, 'gtk-theme'), quote('Example-Dark'))
        self.assertEqual(self.settings.get(INTERFACE, 'icon-theme'), quote('Example'))

    def test_extraction_applies_only_explicit_link_repair(self):
        source = self.home / 'input.tar'
        source.write_bytes(ArchiveTests().archive([
            ('root/Icons/a', 'asset', 'file'), ('root/Icons/b', '/author/Icons/a', 'link')]).read())
        output = self.home / 'output'
        output.mkdir()
        extract_archive(source, output, link_prefixes={'/author/Icons/': 'Icons/'})
        self.assertEqual((output / 'root/Icons/b').read_text(), 'asset')

    def test_sandbox_links_are_relocated_before_copying(self):
        from studio import normalize_build_links, copy_assets
        output = self.home / 'output'
        source = self.home / 'source'
        source.mkdir()
        output.mkdir()
        (output / '32').mkdir()
        (output / '32/icon.svg').write_text('icon')
        (output / '22').symlink_to('/output/32')
        normalize_build_links(output, source)
        target = self.home / 'installed'
        copy_assets(output, target, self.home, 'icons')
        self.assertEqual((target / '22/icon.svg').read_text(), 'icon')
        self.assertTrue((target / '22').resolve().is_relative_to(target))

    def test_look_checks_shell_before_installing_anything(self):
        del self.settings.values[SHELL, 'name']
        with patch.object(self.studio, 'install') as install:
            with self.assertRaisesRegex(StudioError, 'User Themes'):
                self.studio.apply_look('aurora-dark')
            install.assert_not_called()

    def test_saved_look_preserves_separate_gtk4_theme(self):
        theme = self.theme('GTK4-Only')
        self.studio.apply(gtk='Adwaita', gtk4_theme=theme.name)
        self.studio.save_look('separate-gtk4')
        look = json.loads((self.studio.assets / 'looks.json').read_text())['separate-gtk4']
        self.assertEqual(look['settings']['gtk'], 'Adwaita')
        self.assertEqual(look['settings']['gtk4_theme'], 'GTK4-Only')

    def test_copy_preserves_sibling_theme_links_after_staging_is_removed(self):
        import shutil
        from studio import copy_assets
        stage = self.home / 'stage'
        first, second = stage / 'Icons', stage / 'Icons-Dark'
        first.mkdir(parents=True)
        second.mkdir()
        (first / 'icon.svg').write_text('icon')
        (second / 'icon.svg').symlink_to('../Icons/icon.svg')
        output = self.home / 'installed'
        output.mkdir()
        mapping = {first: output / 'Icons', second: output / 'Icons-Dark'}
        for source, target in mapping.items():
            copy_assets(source, target, stage, 'icons', mapping)
        shutil.rmtree(stage)
        self.assertTrue((output / 'Icons-Dark/icon.svg').is_symlink())
        self.assertEqual((output / 'Icons-Dark/icon.svg').read_text(), 'icon')

    def test_invalid_registry_shape_has_actionable_error(self):
        atomic_json(self.studio.state / 'installed.json', [])
        with self.assertRaisesRegex(StudioError, 'Invalid installed-family manifest'):
            self.studio.registry()


if __name__ == '__main__':
    unittest.main()
