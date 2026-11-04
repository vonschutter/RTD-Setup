"""Check distro dependency declarations and packaged/local schema layouts."""
import shutil
import subprocess
import tempfile
from pathlib import Path
import unittest

MODULE = Path(__file__).resolve().parents[1]
LAUNCHER = MODULE / 'rtd-theme-studio'
REPAIR = MODULE.parent / 'gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer'


def function(name):
    return name + '() {' + LAUNCHER.read_text().split(
        name + '() {', 1
    )[1].split('\n}', 1)[0] + '\n}\n'


class LauncherDependencyTests(unittest.TestCase):
    def test_fedora_and_redhat_include_resource_compiler_provider(self):
        for distro in ('fedora', 'redhat'):
            with self.subTest(distro=distro):
                result = subprocess.run(
                    ['bash', '-c', function('theme_studio::packages') +
                     '\ntheme_studio::packages "$1"', 'test', distro],
                    capture_output=True, text=True, check=True,
                )
                self.assertIn('glib2-devel', result.stdout.splitlines())

    def test_global_schema_does_not_require_extension_local_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            extension = Path(directory) / 'extensions/user-theme@gnome-shell-extensions.gcampax.github.com'
            extension.mkdir(parents=True)
            (extension / 'metadata.json').write_text('{}')
            # Fedora puts the schema in the global source, leaving no schemas/
            # directory inside the extension. This is a valid, unrepaired layout.
            self.assertFalse(self.needs_repair(directory))

    def needs_repair(self, directory):
        source = function('theme_studio::user_theme_schema_needs_repair').replace(
            '/usr/share/gnome-shell/extensions', directory + '/extensions'
        ).replace('/usr/local/share/gnome-shell/extensions', directory + '/local-extensions')
        result = subprocess.run(
            ['bash', '-c', source + '\ntheme_studio::user_theme_schema_needs_repair'],
            capture_output=True, text=True,
        )
        self.assertIn(result.returncode, (0, 1), result.stderr)
        return result.returncode == 0

    @unittest.skipUnless(shutil.which('glib-compile-schemas'), 'GLib tools are unavailable')
    def test_empty_directory_and_local_schema_repair_reach_healthy_state(self):
        for local_xml in (False, True):
            with self.subTest(local_xml=local_xml), tempfile.TemporaryDirectory() as directory:
                root = Path(directory) / 'extensions'
                extension = root / 'user-theme@gnome-shell-extensions.gcampax.github.com'
                schemas = extension / 'schemas'
                schemas.mkdir(parents=True)
                (extension / 'metadata.json').write_text('{}')
                if local_xml:
                    (schemas / 'org.example.test.gschema.xml').write_text(
                        '<schemalist><schema id="org.example.test" path="/org/example/test/">'
                        '<key name="name" type="s"><default>\'default\'</default></key>'
                        '</schema></schemalist>'
                    )
                self.assertTrue(self.needs_repair(directory))
                result = subprocess.run(
                    ['bash', str(REPAIR), '--repair', str(root)], text=True, capture_output=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(self.needs_repair(directory))
                self.assertEqual(schemas.exists(), local_xml)
                if local_xml:
                    self.assertTrue((schemas / 'gschemas.compiled').is_file())

    def test_missing_metadata_requires_repair(self):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / 'extensions/user-theme@gnome-shell-extensions.gcampax.github.com').mkdir(parents=True)
            self.assertTrue(self.needs_repair(directory))


if __name__ == '__main__':
    unittest.main()
