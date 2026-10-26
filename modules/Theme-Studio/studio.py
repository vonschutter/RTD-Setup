#!/usr/bin/env python3
"""Theme Studio's shared, user-local backend and command-line interface."""
from __future__ import annotations

import argparse
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent
INTERFACE = 'org.gnome.desktop.interface'
BACKGROUND = 'org.gnome.desktop.background'
SHELL = 'org.gnome.shell.extensions.user-theme'
ACCENTS = ('blue', 'teal', 'green', 'yellow', 'orange', 'red', 'pink', 'purple', 'slate')
COLORS = ('#3584e4', '#2190a4', '#3a944a', '#c88800', '#ed5b00', '#e62d42', '#d56199', '#9141ac', '#6f8396')


class StudioError(Exception):
    """An actionable error suitable for display in either frontend."""


def atomic_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    try:
        with temporary.open('x', encoding='utf-8') as stream:
            json.dump(data, stream, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def read_json(path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text())
    except (ValueError, OSError) as error:
        raise StudioError(f'Cannot read {path}: {error}; preserve this file for recovery.') from error


def run(argv, **kwargs):
    kwargs.setdefault('input', '')
    try:
        result = subprocess.run(argv, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=600, **kwargs)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise StudioError(f'{argv[0]} could not finish: {error}') from error
    if result.returncode:
        output = re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', result.stdout)
        raise StudioError(f'{argv[0]} failed:\n{output[-5000:]}')
    return result.stdout


def catalog():
    return read_json(HERE / 'catalog.json', [])


def looks():
    """Thirty original coordinated presets using pinned community theme families."""
    names = ['Aurora', 'Graphite', 'Lagoon', 'Ember', 'Orchid', 'Forest', 'Rose',
             'Nord', 'Sunrise', 'Cobalt', 'Moss', 'Plum', 'Copper', 'Ocean', 'Slate']
    accents = [0, 8, 1, 4, 7, 2, 6, 0, 3, 0, 2, 7, 4, 1, 8]
    themes = [entry['id'] for entry in catalog() if entry['kind'] == 'theme']
    themes[5] = 'catppuccin'
    icon_pairs = [('tela', 'tela-circle'), ('whitesur-icons', 'whitesur-icons'),
                  ('colloid-icons', 'colloid-icons'), ('papirus', 'papirus'),
                  ('fluent-icons', 'fluent-icons'), ('papirus', 'papirus'),
                  ('qogir-icons', 'qogir-icons'), ('numix-circle', 'numix-circle'),
                  ('mcmojave-circle', 'mcmojave-circle'), ('zafiro', 'zafiro'),
                  ('candy', 'candy'), ('tela', 'tela'), ('reversal', 'reversal'),
                  ('la-capitaine', 'la-capitaine'), ('numix', 'numix')]
    return [dict(id=f'{name.lower()}-{mode}', name=f'{name} {mode.title()}',
                 theme_family=themes[index], icon_family=icon_pairs[index][mode == 'dark'],
                 mode=mode, accent=ACCENTS[accents[index]], color=COLORS[accents[index]],
                 style=index, gtk='Adwaita-dark' if mode == 'dark' else 'Adwaita',
                 icons='Adwaita', shell='')
            for index, name in enumerate(names) for mode in ('light', 'dark')]


def extract_archive(archive, destination, exclude_top=(), link_prefixes=None):
    """Extract bounded regular files/directories, then safe internal symlinks only."""
    with tarfile.open(archive) as source:
        members = [m for m in source.getmembers()
                   if not (len(PurePosixPath(m.name).parts) > 1 and PurePosixPath(m.name).parts[1].lower() in exclude_top)]
        if len(members) > 150000 or sum(m.size for m in members) > 1500 * 1024 * 1024:
            raise StudioError('Archive exceeds the extraction limit.')
        links = []
        for member in members:
            name = PurePosixPath(member.name)
            if name.is_absolute() or '..' in name.parts:
                raise StudioError('Unsafe path in theme archive.')
            target = destination.joinpath(*name.parts)
            if not target.resolve().is_relative_to(destination.resolve()):
                raise StudioError('Archive path leaves its destination.')
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(member) as reader, target.open('xb') as writer:
                    shutil.copyfileobj(reader, writer)
                target.chmod(0o755 if member.mode & 0o111 else 0o644)
            elif member.issym():
                links.append((target, member.linkname))
            else:
                raise StudioError('Archive contains a device, hard link, or unsupported entry.')
        for target, link in links:
            for prefix, relative in (link_prefixes or {}).items():
                if link.startswith(prefix):
                    root_name = target.relative_to(destination).parts[0]
                    fixed = destination / root_name / relative / link[len(prefix):]
                    link = os.path.relpath(fixed, target.parent)
                    break
            if Path(link).is_absolute() or not (target.parent / link).resolve().is_relative_to(destination.resolve()):
                raise StudioError('Unsafe symbolic link in theme archive.')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(link)
        for target, _ in links:
            try:
                if not target.resolve().is_relative_to(destination.resolve()):
                    raise StudioError('Symbolic link chain leaves the archive.')
            except RuntimeError as error:
                raise StudioError('Cyclic symbolic link in archive.') from error


def copy_assets(source, destination, boundary, kind, sibling_roots=None):
    """Materialize valid internal links with cycle/size checks, omitting dead links."""
    runtime = {'gtk-2.0', 'gtk-3.0', 'gtk-4.0', 'gnome-shell', 'cinnamon', 'metacity-1',
               'xfwm4', 'unity', 'assets', 'index.theme', 'plank'}
    count = total = skipped = 0
    boundary_root = boundary.resolve()
    source_root = source.resolve()
    link_roots = {source_root: destination, **(sibling_roots or {})}

    def copy(item, target, ancestors, depth=0):
        nonlocal count, total, skipped
        try:
            resolved = item.resolve()
        except RuntimeError as error:
            raise StudioError('Cyclic asset link.') from error
        if not resolved.is_relative_to(boundary_root):
            raise StudioError(f'External asset link: {item.name}')
        if item.is_symlink() and not item.exists():
            skipped += 1
            return
        if item.is_symlink() and kind == 'icons':
            if item.is_dir() and resolved in ancestors:
                raise StudioError('Cyclic asset directory link.')
            for original, installed in link_roots.items():
                if resolved.is_relative_to(original):
                    mapped = installed / resolved.relative_to(original)
                    target.symlink_to(os.path.relpath(mapped, target.parent))
                    return
        count += 1
        if count > 150000 or depth > 50:
            raise StudioError('Asset tree exceeds safety limits.')
        if item.is_dir():
            if resolved in ancestors:
                raise StudioError('Cyclic asset directory link.')
            target.mkdir()
            for child in sorted(item.iterdir()):
                if depth == 0 and kind == 'theme' and child.name not in runtime and not re.match(r'(licen[sc]e|copying|notice)', child.name, re.I):
                    continue
                copy(child, target / child.name, ancestors | {resolved}, depth + 1)
        elif item.is_file():
            total += item.stat().st_size
            if total > 1500 * 1024 * 1024:
                raise StudioError('Expanded assets exceed 1.5 GiB.')
            shutil.copyfile(item, target)
            target.chmod(0o644)
        else:
            raise StudioError('Asset is not a regular file or directory.')

    copy(source, destination, set())
    return skipped


def normalize_build_links(output, source):
    """Translate absolute paths emitted inside the sandbox to staged relative links."""
    for path in output.rglob('*'):
        if not path.is_symlink():
            continue
        link = os.readlink(path)
        for prefix, directory in (('/output/', output), ('/source/', source)):
            if link.startswith(prefix):
                target = directory / link[len(prefix):]
                if not target.resolve().is_relative_to(directory.resolve()):
                    raise StudioError('Build link leaves its staged directory.')
                path.unlink()
                path.symlink_to(os.path.relpath(target, path.parent))
                break


class Settings:
    def __init__(self):
        try:
            from gi.repository import Gio, GLib
        except ImportError as error:
            raise StudioError('Install Python GObject bindings to manage GNOME settings.') from error
        self.Gio, self.GLib = Gio, GLib
        self.source = Gio.SettingsSchemaSource.get_default()
        self.cache = {}
        # User-installed extensions often ship schemas outside the global search path.
        extension = Path.home() / '.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/schemas'
        if (extension / 'gschemas.compiled').exists():
            self.source = Gio.SettingsSchemaSource.new_from_directory(str(extension), self.source, False)

    def setting(self, schema):
        if schema not in self.cache:
            definition = self.source.lookup(schema, True) if self.source else None
            if not definition:
                raise StudioError(f'Missing GNOME schema: {schema}. Shell themes need the User Themes extension installed and enabled.')
            self.cache[schema] = self.Gio.Settings.new_full(definition, None, None)
        return self.cache[schema]

    def has(self, schema, key):
        try:
            return self.setting(schema).props.settings_schema.has_key(key)
        except StudioError:
            return False

    def get(self, schema, key):
        return self.setting(schema).get_value(key).print_(True)

    def check(self, schema, key, value):
        settings = self.setting(schema)
        if not self.has(schema, key) or not settings.is_writable(key):
            raise StudioError(f'Setting is unavailable or locked: {schema} / {key}')
        definition = settings.props.settings_schema.get_key(key)
        try:
            parsed = self.GLib.Variant.parse(definition.get_value_type(), value, None, None)
        except self.GLib.Error as error:
            raise StudioError(f'Invalid value for {key}: {error}') from error
        if not definition.range_check(parsed):
            raise StudioError(f'Unsupported value for {key}: {value}')
        return parsed

    def set(self, schema, key, value):
        parsed = self.check(schema, key, value)
        if not self.setting(schema).set_value(key, parsed):
            raise StudioError(f'Could not write {schema} / {key}')
        self.Gio.Settings.sync()
        if self.get(schema, key) != parsed.print_(True):
            raise StudioError(f'GNOME did not persist {key}; check the session D-Bus connection.')

    def default(self, schema, key):
        return self.setting(schema).get_default_value(key).print_(True)


class Studio:
    def __init__(self, home=None, settings=None):
        self.home = Path(home or Path.home()).resolve()
        self.data = self._xdg('XDG_DATA_HOME', '.local/share')
        self.config = self._xdg('XDG_CONFIG_HOME', '.config')
        self.state = self._xdg('XDG_STATE_HOME', '.local/state') / 'rtd-theme-studio'
        self.assets = self.data / 'rtd-theme-studio'
        self.settings_backend = settings

    def _xdg(self, variable, fallback):
        path = Path(os.environ.get(variable, str(self.home / fallback)))
        if not path.is_absolute() or not path.resolve().is_relative_to(self.home):
            raise StudioError(f'{variable} must be an absolute directory inside your home.')
        return path

    @property
    def settings(self):
        if self.settings_backend is None:
            self.settings_backend = Settings()
        return self.settings_backend

    def safe(self, path):
        if not path.resolve().is_relative_to(self.home):
            raise StudioError(f'Refusing to modify a path outside your home: {path}')
        return path

    @contextlib.contextmanager
    def lock(self):
        self.safe(self.state).mkdir(parents=True, exist_ok=True)
        with (self.state / 'lock').open('a') as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise StudioError('Another Theme Studio operation is running.') from error
            yield

    def registry(self):
        registry = read_json(self.state / 'installed.json', {})
        if not isinstance(registry, dict) or any(
            not isinstance(key, str) or not isinstance(entry, dict)
            or not isinstance(entry.get('paths'), list)
            or not all(isinstance(path, str) for path in entry['paths'])
            for key, entry in registry.items()
        ):
            raise StudioError('Invalid installed-family manifest. Preserve installed.json for recovery.')
        return registry

    def installed(self):
        result = {key: {} for key in ('gtk', 'shell', 'icons', 'cursor')}
        roots = [self.data, self.home / '.local/share', Path('/usr/local/share'), Path('/usr/share')]
        theme_roots = [self.home / '.themes'] + [root / 'themes' for root in roots]
        icon_roots = [self.home / '.icons'] + [root / 'icons' for root in roots]
        for root in reversed(theme_roots):
            if root.is_dir():
                for path in sorted(root.iterdir()):
                    if (path / 'gtk-3.0/gtk.css').is_file():
                        result['gtk'][path.name] = str(path)
                    if (path / 'gnome-shell/gnome-shell.css').is_file():
                        result['shell'][path.name] = str(path)
        for root in reversed(icon_roots):
            if root.is_dir():
                for path in sorted(root.iterdir()):
                    if (path / 'index.theme').is_file():
                        result['icons'][path.name] = str(path)
                    if (path / 'cursors').is_dir():
                        result['cursor'][path.name] = str(path)
        # GTK's built-in Adwaita styles do not require external CSS files.
        result['gtk'].setdefault('Adwaita', '')
        result['gtk'].setdefault('Adwaita-dark', '')
        return result

    def wallpaper(self, look):
        path = self.safe(self.assets / 'wallpapers' / (look['id'] + '.svg'))
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            bg = '#121822' if look['mode'] == 'dark' else '#edf2f7'
            offset = 200 + look['style'] * 130
            path.write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 3840 2160">
<defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="{bg}"/><stop offset="1" stop-color="{look['color']}"/></linearGradient><radialGradient id="h"><stop stop-color="{look['color']}" stop-opacity=".8"/><stop offset="1" stop-color="{bg}" stop-opacity="0"/></radialGradient></defs>
<rect width="3840" height="2160" fill="url(#g)"/><ellipse cx="{offset}" cy="500" rx="1900" ry="1400" fill="url(#h)"/><path d="M0 1700 Q{offset} 700 3840 1500 V2160 H0Z" fill="{bg}" opacity=".45"/><path d="M0 1950 Q2400 {offset} 3840 1800 V2160 H0Z" fill="{bg}" opacity=".35"/></svg>''')
        return path

    def install(self, family_id, profile="default"):
        entry = next((e for e in catalog() if e['id'] == family_id), None)
        if not entry or not entry.get('revision'):
            raise StudioError('Unknown family or missing pinned source revision.')
        if profile not in entry.get('profiles', {'default': []}):
            raise StudioError('Unsupported build profile for this family.')
        with self.lock():
            registry = self.registry()
            if family_id in registry:
                existing = registry[family_id].get('profile', 'default')
                if existing != profile and profile != 'default':
                    raise StudioError(f'Family already installed with profile {existing}; reset and remove it before choosing another profile.')
                if not all(Path(p).exists() for p in registry[family_id]['paths']):
                    raise StudioError('Managed files are missing. Remove this family and install it again to repair it.')
                return f"Already installed: {entry['name']} ({existing})"
            self.safe(self.assets).mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(prefix='build-', dir=self.assets) as directory:
                stage = Path(directory)
                archive = stage / 'source.tar.gz'
                url = f"https://codeload.github.com/{entry['repository']}/tar.gz/{entry['revision']}"
                digest = hashlib.sha256()
                try:
                    with urllib.request.urlopen(url, timeout=45) as response, archive.open('wb') as output:
                        total = 0
                        while chunk := response.read(1024 * 1024):
                            total += len(chunk)
                            if total > 250 * 1024 * 1024:
                                raise StudioError('Download exceeds 250 MiB limit.')
                            digest.update(chunk)
                            output.write(chunk)
                except OSError as error:
                    raise StudioError(f'Download failed: {error}') from error
                source = stage / 'source'
                source.mkdir()
                extract_archive(archive, source, exclude_top=('icons',) if entry['kind'] == 'theme' else (),
                                link_prefixes=entry.get('link_prefixes'))
                roots = list(source.iterdir())
                if len(roots) != 1 or not roots[0].is_dir():
                    raise StudioError('Source archive does not have one root directory.')
                root = roots[0]
                output = stage / 'output'
                output.mkdir()
                if entry['method'] == 'installer':
                    self.build(root, output, entry, profile)
                    candidates = list(output.iterdir())
                else:
                    marker = 'gtk-3.0/gtk.css' if entry['kind'] == 'theme' else 'index.theme'
                    candidates = sorted({p.parent.parent if entry['kind'] == 'theme' else p.parent
                                         for p in root.rglob(marker)})
                candidates = [p for p in candidates if p.is_dir() and (
                    (p / 'gtk-3.0/gtk.css').exists() or (p / 'index.theme').exists())]
                if not candidates:
                    raise StudioError('This source has no ready-to-install assets. Build support is needed for this revision.')
                destination = self.safe(self.data / ('themes' if entry['kind'] == 'theme' else 'icons'))
                destination.mkdir(parents=True, exist_ok=True)
                targets = []
                for candidate in candidates:
                    name = entry['name'].replace(' ', '-') if candidate == root else candidate.name
                    target = self.safe(destination / name)
                    if target.exists() or target.is_symlink() or target in targets:
                        raise StudioError(f'Will not overwrite an existing theme: {target}')
                    targets.append(target)
                sibling_roots = {candidate.resolve(): target for candidate, target in zip(candidates, targets)}
                copied = []
                skipped = 0
                try:
                    for candidate, target in zip(candidates, targets):
                        copied.append(target)
                        skipped += copy_assets(candidate, target, stage, entry['kind'], sibling_roots)
                    notice_dir = self.safe(self.assets / 'sources' / family_id)
                    notice_dir.mkdir(parents=True, exist_ok=True)
                    for item in root.iterdir():
                        if item.is_file() and re.match(r'(licen[sc]e|copying|notice|readme)', item.name, re.I):
                            shutil.copy2(item, notice_dir / item.name)
                    registry[family_id] = dict(paths=[str(p) for p in targets], repository=entry['repository'],
                                               revision=entry['revision'], sha256=digest.hexdigest(), profile=profile)
                    atomic_json(self.state / 'installed.json', registry)
                except Exception:
                    for target in copied:
                        if target.exists():
                            shutil.rmtree(target)
                    raise
                message = f"Installed {len(targets)} variants of {entry['name']}. Select an installed variant to apply."
                if skipped:
                    message += f' Omitted {skipped} dangling upstream asset links; missing icons use theme inheritance.'
                return message

    def build(self, source, output, entry, profile="default"):
        if not shutil.which('bwrap'):
            raise StudioError('Source builds require bubblewrap (bwrap). Install it using your distribution tools, then retry.')
        missing = [command for command in entry.get('requires', []) if not shutil.which(command)]
        if missing:
            raise StudioError('Missing build tools: ' + ', '.join(missing) + '. Install them with your distribution tools, then retry.')
        build_dir = entry.get('build_dir', '.')
        if not (source / build_dir / 'install.sh').is_file():
            raise StudioError('The pinned source has no supported install.sh.')
        # No user home, network, D-Bus, display, or writable system directories.
        args = ['bwrap', '--unshare-all', '--die-with-parent', '--new-session', '--cap-drop', 'ALL',
                '--clearenv', '--setenv', 'PATH', '/usr/bin:/bin', '--setenv', 'HOME', '/home/builder',
                '--setenv', 'LANG', 'C.UTF-8', '--setenv', 'BATCH_MODE', 'true', '--proc', '/proc', '--dev', '/dev', '--tmpfs', '/tmp',
                '--dir', '/home', '--dir', '/home/builder']
        for name in ('usr', 'bin', 'lib', 'lib64', 'etc'):
            path = Path('/') / name
            if path.exists():
                args += ['--ro-bind', str(path), str(path)]
        for command in ('sudo', 'pkexec', 'apt', 'apt-get', 'dnf', 'yum', 'pacman', 'zypper', 'swupd', 'xbps-install'):
            executable = Path('/usr/bin') / command
            if executable.exists():
                args += ['--ro-bind', '/usr/bin/false', str(executable.resolve())]
        args += ['--bind', str(source), '/source', '--bind', str(output), '/output', '--chdir', '/source' + ('/' + build_dir if build_dir != '.' else ''),
                 'bash', './install.sh', '-d', '/output'] + entry.get('profiles', {'default': []})[profile]
        try:
            run(args)
            normalize_build_links(output, source)
        except StudioError as error:
            raise StudioError(f'Isolated build failed; no desktop settings changed. Some themes need sassc and theme engines.\n{error}') from error

    def uninstall(self, family_id):
        with self.lock():
            registry = self.registry()
            if family_id not in registry:
                raise StudioError('Only families installed by Theme Studio can be removed.')
            paths = [Path(p) for p in registry[family_id]['paths']]
            for path in paths:
                if path.parent not in (self.data / 'themes', self.data / 'icons') or path.is_symlink():
                    raise StudioError('Invalid managed asset path; refusing removal.')
                self.safe(path)
                for schema, key in ((INTERFACE, 'gtk-theme'), (INTERFACE, 'icon-theme'),
                                    (INTERFACE, 'cursor-theme'), (SHELL, 'name')):
                    if self.settings.has(schema, key) and self.settings.get(schema, key) == quote(path.name):
                        raise StudioError('This family is active. Apply another look or reset before removing it.')
                css = self.config / 'gtk-4.0/gtk.css'
                if css.is_file() and path.as_uri() in css.read_text():
                    raise StudioError('GTK4 styling still uses this family. Reset styling before removal.')
            for path in paths:
                if path.exists():
                    shutil.rmtree(path)
            del registry[family_id]
            atomic_json(self.state / 'installed.json', registry)
            return 'Removed managed family.'

    def snapshot(self, changes):
        folder = self.safe(self.state / 'history' / (time.strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8]))
        folder.mkdir(parents=True)
        settings = [[schema, key, self.settings.get(schema, key)] for schema, key, _ in changes]
        gtk = self.safe(self.config / 'gtk-4.0')
        if gtk.is_symlink():
            raise StudioError('GTK4 configuration directory is a symlink; move it to a real directory before applying styling.')
        if gtk.exists():
            shutil.copytree(gtk, folder / 'gtk-4.0', symlinks=True)
        atomic_json(folder / 'snapshot.json', {'settings': settings, 'gtk4_exists': gtk.exists()})
        return folder

    def restore_files(self, folder, snapshot):
        target = self.safe(self.config / 'gtk-4.0')
        if target.is_symlink():
            raise StudioError('GTK4 configuration became a symlink; refusing to replace it.')
        if target.exists():
            shutil.rmtree(target)
        if snapshot['gtk4_exists']:
            shutil.copytree(folder / 'gtk-4.0', target, symlinks=True)

    def rollback(self, folder):
        snapshot = read_json(folder / 'snapshot.json', None)
        if not snapshot:
            raise StudioError('Snapshot is missing.')
        failures = []
        for schema, key, value in reversed(snapshot['settings']):
            try:
                self.settings.set(schema, key, value)
            except StudioError as error:
                failures.append(str(error))
        self.restore_files(folder, snapshot)
        if failures:
            raise StudioError('Some settings could not be restored: ' + '; '.join(failures))

    def transaction(self, changes, gtk4=None, reset_gtk4=False):
        for schema, key, value in changes:
            self.settings.check(schema, key, value)
        with self.lock():
            pending = self.state / 'pending.json'
            if pending.exists():
                raise StudioError('An interrupted change needs recovery. Run rtd-theme-studio recover.')
            folder = self.snapshot(changes)
            atomic_json(pending, {'snapshot': folder.name})
            try:
                if gtk4:
                    target = self.safe(self.config / 'gtk-4.0')
                    target.mkdir(parents=True, exist_ok=True)
                    for name in ('gtk.css', 'gtk-dark.css'):
                        css = target / name
                        if css.is_symlink():
                            css.unlink()
                        source = gtk4 / name
                        if not source.exists():
                            source = gtk4 / 'gtk.css'
                        css.write_text(f'/* RTD Theme Studio */\n@import url("{source.as_uri()}");\n')
                if reset_gtk4:
                    self.clear_gtk4()
                for schema, key, value in changes:
                    self.settings.set(schema, key, value)
            except Exception as error:
                try:
                    self.rollback(folder)
                    pending.unlink()
                except Exception as recovery_error:
                    raise StudioError(f'Change failed: {error}. Recovery also failed: {recovery_error}. Run recover after fixing the session.') from error
                raise StudioError(f'Change failed and was rolled back: {error}') from error
            atomic_json(self.state / 'last.json', {'snapshot': folder.name})
            pending.unlink()
        return 'Appearance applied. Restart open applications; Shell changes may require logging out and back in.'

    def clear_gtk4(self):
        # Restore the user's original files when removing our override.
        baseline = self.state / 'gtk4-original'
        target = self.safe(self.config / 'gtk-4.0')
        if baseline.exists():
            snapshot = read_json(baseline / 'snapshot.json', None)
            self.restore_files(baseline, snapshot)
        elif target.exists():
            for name in ('gtk.css', 'gtk-dark.css'):
                path = target / name
                if path.is_file() and not path.is_symlink() and path.read_text().startswith('/* RTD Theme Studio */'):
                    path.unlink()

    def apply(self, gtk=None, shell=None, icons=None, cursor=None, mode=None, accent=None,
              wallpaper=None, gtk4=False, gtk4_theme=None):
        inventory = self.installed()
        changes = []
        for kind, value, schema, key in [('gtk', gtk, INTERFACE, 'gtk-theme'),
                                         ('icons', icons, INTERFACE, 'icon-theme'),
                                         ('cursor', cursor, INTERFACE, 'cursor-theme'),
                                         ('shell', shell, SHELL, 'name')]:
            if value is None:
                continue
            if not (kind == 'shell' and value == '') and value not in inventory[kind]:
                raise StudioError(f'Install the {kind} variant first: {value}')
            if kind == 'shell':
                if not self.settings.has(SHELL, 'name') and not value:
                    continue
                if value:
                    self.check_shell()
            changes.append((schema, key, quote(value)))
        if mode is not None:
            if mode not in ('light', 'dark'):
                raise StudioError('Mode must be light or dark.')
            changes.append((INTERFACE, 'color-scheme', quote('prefer-dark' if mode == 'dark' else 'default')))
        if accent is not None:
            if accent not in ACCENTS:
                raise StudioError('Unknown accent color.')
            if not self.settings.has(INTERFACE, 'accent-color'):
                raise StudioError('Native accent colors need GNOME 47 or newer. Leave accent unchanged on this desktop.')
            changes.append((INTERFACE, 'accent-color', quote(accent)))
        if wallpaper:
            path = Path(wallpaper).expanduser().resolve()
            if not path.is_file() or path.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.svg', '.webp'):
                raise StudioError('Select an existing PNG, JPEG, SVG, or WebP wallpaper.')
            for key in ('picture-uri', 'picture-uri-dark'):
                if self.settings.has(BACKGROUND, key):
                    changes.append((BACKGROUND, key, quote(path.as_uri())))
            changes.append((BACKGROUND, 'picture-options', quote('zoom')))
        gtk4_path = None
        if gtk4 or gtk4_theme:
            gtk4_theme = gtk4_theme or gtk
            if not gtk4_theme or not inventory['gtk'].get(gtk4_theme):
                raise StudioError('Choose an installed theme with GTK4 CSS.')
            gtk4_path = Path(inventory['gtk'][gtk4_theme]) / 'gtk-4.0'
            if not (gtk4_path / 'gtk.css').is_file():
                raise StudioError('This theme does not provide GTK4 styling.')
            # Preserve the pre-Studio configuration once; transactions retain each prior state.
            with self.lock():
                baseline = self.safe(self.state / 'gtk4-original')
                if not baseline.exists():
                    snapshot = self.snapshot([])
                    shutil.copytree(snapshot, baseline, symlinks=True)
        if not changes and not gtk4_path:
            raise StudioError('No appearance changes selected.')
        return self.transaction(changes, gtk4=gtk4_path)

    def check_shell(self):
        if not self.settings.has(SHELL, 'name'):
            raise StudioError('Complete looks require the GNOME User Themes extension. Install and enable it first, or use Customize for GTK/icons only.')
        enabled = run(['gnome-extensions', 'list', '--enabled']).splitlines()
        if 'user-theme@gnome-shell-extensions.gcampax.github.com' not in enabled:
            raise StudioError('Enable the GNOME User Themes extension, then log out/in if necessary.')

    def apply_look(self, look_id):
        look = next((item for item in looks() if item['id'] == look_id), None)
        if not look:
            saved = read_json(self.assets / 'looks.json', {})
            if look_id not in saved:
                raise StudioError('Unknown look.')
            look = saved[look_id]
            allowed = {'gtk', 'shell', 'icons', 'cursor', 'mode', 'accent', 'wallpaper', 'gtk4', 'gtk4_theme'}
            if not isinstance(look, dict) or not isinstance(look.get('settings'), dict) or set(look['settings']) - allowed:
                raise StudioError('Invalid saved-look settings.')
            if any(not isinstance(value, bool if key == 'gtk4' else str) for key, value in look['settings'].items()):
                raise StudioError('Invalid saved-look setting values.')
            if not isinstance(look.get('families', []), list) or not isinstance(look.get('profiles', {}), dict):
                raise StudioError('Invalid saved-look dependencies.')
            for family in look.get('families', []):
                self.install(family, look.get('profiles', {}).get(family, 'default'))
            return self.apply(**look['settings'])
        self.check_shell()
        for family in (look['theme_family'], look['icon_family']):
            self.install(family)
        registry = self.registry()
        inventory = self.installed()
        def variant(family, kind):
            available = [Path(path).name for path in registry[family]['paths'] if Path(path).name in inventory[kind]]
            if not available:
                raise StudioError(f'No {kind} variants found for {family}.')
            # Prefer matching light/dark names, then the shortest standard variant.
            def score(name):
                lowered = name.lower()
                matches = ('dark' in lowered) if look['mode'] == 'dark' else ('light' in lowered)
                opposite = ('light' in lowered) if look['mode'] == 'dark' else ('dark' in lowered)
                return (opposite, not matches, 'compact' in lowered, len(name), name)
            return sorted(available, key=score)[0]
        gtk = variant(look['theme_family'], 'gtk')
        icons = variant(look['icon_family'], 'icons')
        shell = gtk if gtk in inventory['shell'] else ''
        accent = look['accent'] if self.settings.has(INTERFACE, 'accent-color') else None
        message = self.apply(gtk=gtk, shell=shell, icons=icons, mode=look['mode'],
                             accent=accent, wallpaper=str(self.wallpaper(look)))
        if accent is None:
            message += ' Native accent unchanged: this GNOME version has no accent-color setting.'
        return message

    def save_look(self, name):
        if not re.fullmatch(r'[a-z0-9][a-z0-9-]{0,63}', name) or name in {x['id'] for x in looks()}:
            raise StudioError('Use a unique lowercase look ID (letters, numbers and hyphens, max 64 characters).')
        # Values are strings in GVariant syntax; use GLib rather than evaluating text.
        from gi.repository import GLib
        values = {}
        for field, schema, key in [('gtk', INTERFACE, 'gtk-theme'), ('icons', INTERFACE, 'icon-theme'),
                                    ('cursor', INTERFACE, 'cursor-theme'), ('shell', SHELL, 'name'),
                                    ('accent', INTERFACE, 'accent-color'), ('wallpaper', BACKGROUND, 'picture-uri')]:
            if self.settings.has(schema, key):
                value = GLib.Variant.parse(None, self.settings.get(schema, key), None, None).unpack()
                if field == 'wallpaper':
                    from urllib.parse import urlparse, unquote
                    uri = urlparse(value)
                    if uri.scheme != 'file':
                        continue
                    value = unquote(uri.path)
                values[field] = value
        css = self.config / 'gtk-4.0/gtk.css'
        if css.is_file() and css.read_text().startswith('/* RTD Theme Studio */'):
            for theme, path in self.installed()['gtk'].items():
                if path and (Path(path) / 'gtk-4.0/gtk.css').as_uri() in css.read_text():
                    values['gtk4'] = True
                    values['gtk4_theme'] = theme
                    break
        values['mode'] = 'dark' if 'prefer-dark' in self.settings.get(INTERFACE, 'color-scheme') else 'light'
        registry = self.registry()
        selected = {values.get(k) for k in ('gtk', 'icons', 'cursor', 'shell', 'gtk4_theme')}
        families = [key for key, entry in registry.items() if any(Path(p).name in selected for p in entry['paths'])]
        with self.lock():
            saved = read_json(self.assets / 'looks.json', {})
            saved[name] = {'settings': values, 'families': families,
                           'profiles': {f: registry[f].get('profile', 'default') for f in families}}
            atomic_json(self.assets / 'looks.json', saved)
        return f'Saved {name}.'

    def reset(self, ubuntu=False):
        changes = []
        inventory = self.installed()
        if ubuntu and ('Yaru' not in inventory['gtk'] or 'Yaru' not in inventory['icons']):
            raise StudioError('Ubuntu reset requires the Yaru GTK and icon themes to be installed.')
        for schema, keys in [(INTERFACE, ('gtk-theme', 'icon-theme', 'cursor-theme', 'color-scheme', 'accent-color')),
                             (BACKGROUND, ('picture-uri', 'picture-uri-dark', 'picture-options')), (SHELL, ('name',))]:
            for key in keys:
                if self.settings.has(schema, key):
                    value = self.settings.default(schema, key)
                    if ubuntu and key in ('gtk-theme', 'icon-theme'):
                        value = quote('Yaru')
                    if ubuntu and key == 'color-scheme':
                        value = quote('default')
                    if key == 'name':
                        value = quote('')
                    changes.append((schema, key, value))
        return self.transaction(changes, reset_gtk4=True)

    def recover(self, undo=False):
        with self.lock():
            pointer = self.state / ('last.json' if undo else 'pending.json')
            if undo and (self.state / 'pending.json').exists():
                raise StudioError('Recover the interrupted change before undoing a previous change.')
            record = read_json(pointer, None)
            if not record:
                raise StudioError('No change available to undo.' if undo else 'No interrupted operation to recover.')
            name = record['snapshot']
            if Path(name).name != name:
                raise StudioError('Invalid recovery snapshot.')
            folder = self.safe(self.state / 'history' / name)
            self.rollback(folder)
            pointer.unlink()
        return 'Previous settings and GTK4 configuration restored.'

    def add_launcher(self):
        path = self.safe(self.data / 'applications/rtd-theme-studio.desktop')
        if path.is_symlink():
            raise StudioError('The app launcher is a symbolic link; refusing to overwrite its target.')
        path.parent.mkdir(parents=True, exist_ok=True)
        executable = str(HERE / 'rtd-theme-studio')
        escaped = executable.replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$').replace('%', '%%')
        path.write_text('[Desktop Entry]\nType=Application\nName=RTD Theme Studio\nComment=Create and manage your GNOME appearance\n'
                        f'Exec="{escaped}"\nIcon=preferences-desktop-theme\nTerminal=false\nCategories=Settings;DesktopSettings;\n')
        return 'Theme Studio added to your app grid.'


def quote(value):
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def terminal(studio):
    actions = ['Browse/apply looks', 'Install a theme/icon family', 'Apply individual elements',
               'Remove a managed family', 'Save current look', 'Undo last change',
               'Reset Ubuntu appearance', 'Reset distribution appearance', 'Recover interrupted change', 'Add to app grid']
    while True:
        print('\nRTD Theme Studio\n' + '\n'.join(f'{i+1}. {name}' for i, name in enumerate(actions)) + '\n0. Exit')
        choice = input('Choose: ').strip()
        try:
            if choice == '0':
                return
            if choice == '1':
                print('\n'.join(f"{x['id']}: {x['name']}" for x in looks()))
                print('Saved:', ', '.join(read_json(studio.assets / 'looks.json', {})))
                print(studio.apply_look(input('Look ID: ').strip()))
            elif choice == '2':
                print('\n'.join(f"{x['id']}: {x['name']} ({x['kind']})" for x in catalog()))
                family = input('Family ID: ').strip()
                entry = next((e for e in catalog() if e['id'] == family), {})
                print('Profiles: ' + ', '.join(entry.get('profiles', {})))
                profile = input('Profile [default]: ').strip() or 'default'
                print(studio.install(family, profile))
            elif choice == '3':
                inventory = studio.installed()
                values = {}
                for key in ('gtk', 'shell', 'icons', 'cursor'):
                    print(f'{key}: ' + ', '.join(inventory[key]))
                    value = input(f'{key} (blank keeps current): ').strip()
                    if value:
                        values[key] = value
                for key in ('mode', 'accent', 'wallpaper'):
                    value = input(f'{key} (blank keeps current): ').strip()
                    if value:
                        values[key] = value
                values['gtk4'] = input('Apply GTK4 CSS too? [y/N]: ').lower() == 'y'
                print(studio.apply(**values))
            elif choice == '4':
                print(', '.join(studio.registry()))
                print(studio.uninstall(input('Family ID: ').strip()))
            elif choice == '5':
                print(studio.save_look(input('New look ID: ').strip()))
            elif choice in ('6', '7', '8', '9', '10'):
                action = {'6': lambda: studio.recover(True), '7': lambda: studio.reset(True),
                          '8': studio.reset, '9': studio.recover, '10': studio.add_launcher}[choice]
                print(action())
        except (StudioError, OSError, ValueError) as error:
            print(f'Error: {error}', file=sys.stderr)


def main(argv=None):
    parser = argparse.ArgumentParser(prog='rtd-theme-studio', description=__doc__)
    parser.add_argument('--terminal', action='store_true', help='Open the interactive terminal interface')
    sub = parser.add_subparsers(dest='command')
    listing = sub.add_parser('list', help='List catalog, looks, installed components, or managed families')
    listing.add_argument('kind', choices=['catalog', 'looks', 'installed', 'managed'])
    listing.add_argument('--search', default='')
    for name in ('install', 'uninstall', 'apply-look', 'save-look'):
        p = sub.add_parser(name)
        p.add_argument('id')
        if name == 'install':
            p.add_argument('--profile', default='default', help='Family build profile; see list catalog for supported profiles')
    apply = sub.add_parser('apply', help='Mix individual installed components')
    for key in ('gtk', 'shell', 'icons', 'cursor', 'wallpaper'):
        apply.add_argument('--' + key)
    apply.add_argument('--mode', choices=['light', 'dark'])
    apply.add_argument('--accent', choices=ACCENTS)
    apply.add_argument('--gtk4', action='store_true')
    apply.add_argument('--gtk4-theme', help='Use a different installed theme for GTK4 CSS')
    reset = sub.add_parser('reset')
    reset.add_argument('--ubuntu', action='store_true')
    for name in ('undo', 'recover', 'add-launcher'):
        sub.add_parser(name)
    args = parser.parse_args(argv)
    if args.terminal and args.command:
        parser.error('--terminal cannot be combined with a subcommand')
    try:
        studio = Studio()
        if args.command == 'list':
            data = {'catalog': catalog, 'looks': lambda: looks() + [{'id': k, **v} for k, v in read_json(studio.assets / 'looks.json', {}).items()],
                    'installed': studio.installed, 'managed': studio.registry}[args.kind]()
            if args.search:
                if isinstance(data, list):
                    data = [v for v in data if args.search.lower() in json.dumps(v).lower()]
                else:
                    data = {k: v for k, v in data.items() if args.search.lower() in (k + json.dumps(v)).lower()}
            print(json.dumps(data, indent=2))
            return 0
        if os.geteuid() == 0:
            raise StudioError('Run Theme Studio as your logged-in desktop user, without sudo.')
        desktop = os.environ.get('XDG_CURRENT_DESKTOP', '').lower()
        if desktop and 'gnome' not in desktop and 'ubuntu' not in desktop:
            raise StudioError('Theme Studio targets GNOME. Use your desktop’s native appearance settings.')
        if args.terminal:
            terminal(studio)
        elif not args.command:
            from studio_gtk import launch
            launch(studio)
        elif args.command == 'apply':
            print(studio.apply(**{k: v for k, v in vars(args).items() if k not in ('command', 'terminal')}))
        else:
            actions = {'install': lambda: studio.install(args.id, args.profile), 'uninstall': lambda: studio.uninstall(args.id),
                       'apply-look': lambda: studio.apply_look(args.id), 'save-look': lambda: studio.save_look(args.id),
                       'reset': lambda: studio.reset(args.ubuntu), 'undo': lambda: studio.recover(True),
                       'recover': studio.recover, 'add-launcher': studio.add_launcher}
            print(actions[args.command]())
        return 0
    except (StudioError, OSError, ValueError, tarfile.TarError) as error:
        print(f'Theme Studio: {error}', file=sys.stderr)
        return 1
    except (KeyboardInterrupt, EOFError):
        return 130


if __name__ == '__main__':
    sys.exit(main())
