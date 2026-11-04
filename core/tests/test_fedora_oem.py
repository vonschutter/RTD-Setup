"""Fedora GNOME must use native GDM first-user setup and fail unavailable fallbacks."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

from test_oem_themes import library_function


class FedoraOemTests(unittest.TestCase):
    def test_gdm_handoff_propagates_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            binary = Path(directory) / 'gdm'
            binary.touch()
            binary.chmod(0o755)
            function = library_function('system::rtd_oem_reseal::_prepare_fedora').replace(
                '/usr/sbin/gdm', str(binary)
            ).replace('/var/lib/rtd', directory + '/state')
            for code in (0, 17):
                result = subprocess.run(
                    ['bash', '-c', """
write_status() { :; }
system::rtd_oem_reseal::_prepare_gdm_first_user() { echo gdm; return "$RESULT"; }
software::check_native_package_dependency() { echo UNEXPECTED-FALLBACK; }
grubby() { return 0; }
""" + function + '\nsystem::rtd_oem_reseal::_prepare_fedora physical'],
                    env={**os.environ, 'RESULT': str(code), '_LOGFILE': str(Path(directory) / 'log')}, text=True, capture_output=True,
                )
                self.assertEqual(result.returncode, 0 if code == 0 else 1, result.stderr)
                self.assertIn('gdm', result.stdout)
                self.assertNotIn('UNEXPECTED-FALLBACK', result.stdout)

    def test_missing_native_fallback_cannot_report_reseal_ready(self):
        function = library_function('system::rtd_oem_reseal::_prepare_fedora').replace(
            '/usr/sbin/gdm', '/nonexistent-rtd-test/gdm'
        )
        result = subprocess.run(['bash', '-c', """
write_status() { :; }
software::check_native_package_dependency() { return 23; }
systemctl() { echo UNEXPECTED-ENABLE; }
""" + function + '\nsystem::rtd_oem_reseal::_prepare_fedora physical'],
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('UNEXPECTED-ENABLE', result.stdout)

    def test_gdm_preparation_updates_fedora_config(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'etc/gdm/custom.conf'
            config.parent.mkdir(parents=True)
            # The finalizer removed the temporary autologin file; only its directory remains.
            executable = root / 'usr/libexec/gnome-initial-setup'
            executable.parent.mkdir(parents=True)
            executable.touch()
            executable.chmod(0o755)
            session = root / 'usr/share/gnome-session/sessions/gnome-initial-setup.session'
            session.parent.mkdir(parents=True)
            session.touch()
            function = library_function('system::rtd_oem_reseal::_prepare_gdm_first_user')
            function = re.sub(
                r'/usr/sbin/gdm3|/etc/gdm3|/etc/gdm|/var/lib/AccountsService|/var/lib/oem-config|/run/gdm3|/run/gdm|/usr/libexec|/usr/share/gnome-session',
                lambda match: directory + match.group(), function,
            )
            result = subprocess.run(['bash', '-c', """
write_error() { echo "$*" >&2; }
id() {
    [[ "$*" == "-u recovery" ]] && { echo 29998; return 0; }
    [[ "$*" == recovery ]]
}
getent() { return 2; }
software::check_native_package_dependency() { return 0; }
systemctl() { [[ "$1" != get-default ]] || echo graphical.target; return 0; }
""" + function + '\nsystem::rtd_oem_reseal::_prepare_gdm_first_user physical'],
                                    text=True, capture_output=True,
                                    env={**os.environ, 'SUDO_USER': 'recovery',
                                         '_LOGFILE': str(root / 'log')})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('InitialSetupEnable=True', config.read_text())
            self.assertNotIn('AutomaticLoginEnable=True', config.read_text())
            self.assertNotIn('AutomaticLogin=recovery', config.read_text())
            self.assertFalse((root / 'etc/gdm3').exists())
            self.assertIn('SystemAccount=true',
                          (root / 'var/lib/AccountsService/users/recovery').read_text())

    def test_delivery_boot_flag_is_removed_only_for_deployed_user(self):
        for uid, tool_result in ((1000, 0), (1000, 23), (29998, 0)):
            with self.subTest(uid=uid, tool_result=tool_result), tempfile.TemporaryDirectory() as directory:
                marker = Path(directory) / 'marker'
                marker.touch()
                function = library_function('system::rtd_oem_reseal::_complete_gdm_first_user').replace(
                    '/var/lib/rtd/gnome-initial-setup-boot-arg', str(marker)
                )
                result = subprocess.run(['bash', '-c', """
id() { echo "$TEST_UID"; }
grubby() { echo "$*"; return "$TOOL_RESULT"; }
""" + function + '\nsystem::rtd_oem_reseal::_complete_gdm_first_user'],
                                        capture_output=True, text=True,
                                        env={**os.environ, 'SUDO_USER': 'deployed',
                                             'TEST_UID': str(uid), 'TOOL_RESULT': str(tool_result),
                                             '_LOGFILE': str(Path(directory) / 'log')})
                success = uid == 1000 and tool_result == 0
                self.assertEqual(result.returncode == 0, success, result.stderr)
                self.assertEqual(marker.exists(), not success)
                if success:
                    self.assertIn('--remove-args=gnome.initial-setup',
                                  (Path(directory) / 'log').read_text())

    def test_kickstart_reserves_first_user_uid(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'ks.cfg'
            result = subprocess.run(
                ['bash', '-c', 'write_information() { :; }\n' +
                 library_function('template::kickstart_cfg') +
                 '\ntemplate::kickstart_cfg "$_ks_file"'],
                capture_output=True, text=True,
                env={**os.environ, '_ks_file': str(target), '_role': 'workstation'},
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            content = target.read_text()
            self.assertIn('user --groups=wheel --uid=29998', content)
            self.assertIn('reboot --eject', content)
            self.assertIn('systemctl enable sshd', content)


if __name__ == '__main__':
    unittest.main()
