"""Native GTK preview checks using disposable assets and in-memory settings."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODULE))

try:
    import gi
    gi.require_version('Gtk', '4.0')
    gi.require_version('Adw', '1')
    from gi.repository import Gtk
    GTK_AVAILABLE = True
except (ImportError, ValueError):
    GTK_AVAILABLE = False


@unittest.skipUnless(GTK_AVAILABLE, 'GTK4/Libadwaita bindings are unavailable')
class PreviewMemoryTests(unittest.TestCase):
    def test_all_previews_are_bounded_without_modifying_wallpapers(self):
        from studio import Studio, looks
        from studio_gtk import thumbnail_texture

        with tempfile.TemporaryDirectory() as directory:
            # Override XDG paths only in the test's isolated Studio instance.
            from unittest.mock import patch
            with patch.dict(os.environ, {name: str(Path(directory) / name) for name in (
                'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME'
            )}):
                studio = Studio(home=directory)
                for look in looks():
                    source = studio.wallpaper(look)
                    before = source.read_bytes()
                    texture = thumbnail_texture(source)
                    self.assertEqual((texture.get_width(), texture.get_height()), (560, 315))
                    self.assertEqual(source.read_bytes(), before)
                    self.assertIn(b'width="3840" height="2160"', before)

    def test_open_gallery_stays_below_memory_budget(self):
        if not Gtk.init_check():
            self.skipTest('No graphical display')
        script = """
import json, os, resource, sys, tempfile
sys.path.insert(0, sys.argv[1])
from studio import Studio
from studio_gtk import create_application
from gi.repository import GLib
with tempfile.TemporaryDirectory() as home:
    for name in ('XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME'):
        os.environ.pop(name, None)
    app = create_application(Studio(home=home))
    def measure():
        print(json.dumps({'peak_kib': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}))
        app.quit()
        return False
    GLib.timeout_add_seconds(3, measure)
    app.run([])
"""
        result = subprocess.run(
            [sys.executable, '-c', script, str(MODULE)], capture_output=True,
            text=True, timeout=30,
            env={**os.environ, 'GSETTINGS_BACKEND': 'memory', 'GSK_RENDERER': 'cairo',
                 'PYTHONDONTWRITEBYTECODE': '1'},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        peak = json.loads(result.stdout.strip().splitlines()[-1])['peak_kib']
        # A 2 GiB guest must also accommodate GNOME and the rest of the system.
        # Full-resolution gallery decoding exceeds this deliberately loose budget.
        self.assertLess(peak, 768 * 1024, f'Gallery peak was {peak / 1024:.0f} MiB')


if __name__ == '__main__':
    unittest.main()
