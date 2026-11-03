"""Debian first-user setup and static SPICE unit regression checks."""

import os
import re
from pathlib import Path
import subprocess
import tempfile
import unittest

from test_oem_themes import library_function


class DebianOemTests(unittest.TestCase):
    def test_preseed_reserves_first_user_only_for_gnome_desktops(self):
        function = library_function('template::preseed_cfg::main')
        for role, task, reserved in (
            ('VDI', 'gnome-desktop', True),
            ('desktop', 'gnome-desktop', True),
            ('workstation', 'gnome-desktop', True),
            ('server', 'ssh-server', False),
            ('VDI', 'kde-desktop', False),
        ):
            with self.subTest(role=role, task=task), tempfile.TemporaryDirectory() as directory:
                target = Path(directory) / 'preseed'
                result = subprocess.run(
                    ['bash', '-c', function + '\ntemplate::preseed_cfg::main "$TARGET"'],
                    capture_output=True, text=True, check=False,
                    env={**os.environ, 'TARGET': str(target), '_role': role, '_task': task},
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual('passwd/user-uid string 29998' in target.read_text(), reserved)

    def test_debian_cannot_clean_identity_after_failed_first_user_preparation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gdm = root / 'gdm3'
            gdm.touch()
            gdm.chmod(0o755)
            function = library_function('system::rtd_oem_reseal::_prepare_debian')
            function = function.replace('/usr/sbin/gdm3', str(gdm)).replace('/usr/sbin/gdm', str(root / 'gdm'))
            script = """
write_status() { :; }
system::rtd_oem_reseal::_prepare_gdm_first_user() { echo first-user; return 17; }
software::add_native_package() { echo UNEXPECTED-CLEANUP; }
truncate() { echo UNEXPECTED-CLEANUP; }
rm() { echo UNEXPECTED-CLEANUP; }
ln() { echo UNEXPECTED-CLEANUP; }
""" + function + '\nsystem::rtd_oem_reseal::_prepare_debian virtual'
            result = subprocess.run(['bash', '-c', script], text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('first-user', result.stdout)
            self.assertNotIn('UNEXPECTED-CLEANUP', result.stdout)

    def test_static_spice_unit_is_attached_to_graphical_session(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            unit = root / 'usr/lib/systemd/user/spice-vdagent.service'
            unit.parent.mkdir(parents=True)
            # Debian 13 ships this static unit without an [Install] section.
            unit.write_text('[Service]\nExecStart=/usr/bin/spice-vdagent -x\n')
            autostart = root / 'etc/xdg/autostart/spice-vdagent.desktop'
            autostart.parent.mkdir(parents=True)
            autostart.write_text('[Desktop Entry]\nExec=spice-vdagent\n')
            function = library_function('system::rtd_oem_reseal::_install_guest_additions')
            function = re.sub(
                r'/etc/xdg|/etc/systemd|/usr/lib/systemd|/lib/systemd',
                lambda match: str(root) + match.group(), function,
            )
            script = """
write_status() { :; }
software::add_native_package() { :; }
apt-mark() { :; }
systemctl() {
    echo "$*" >> "$RECORD"
    [[ "$*" != "--global enable spice-vdagent.service" ]]
}
""" + function + '\nsystem::rtd_oem_reseal::_install_guest_additions'
            result = subprocess.run(
                ['bash', '-c', script], capture_output=True, text=True,
                env={**os.environ, 'RECORD': str(root / 'events'), '_LOGFILE': str(root / 'log')},
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('--global add-wants graphical-session.target spice-vdagent.service',
                          (root / 'events').read_text())
            self.assertIn('Hidden=true', autostart.read_text())


if __name__ == '__main__':
    unittest.main()
