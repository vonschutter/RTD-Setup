"""Best-effort package requests and strict dependency enforcement."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from test_oem_themes import library_function


class NativePackagePolicyTests(unittest.TestCase):
    def run_request(self, request):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = """
set -e
security::ensure_admin() { return 0; }
dependency::os_linux() { return 0; }
system::distribution_type() { echo debian; }
system::log_item() { :; }
write_status() { :; }
write_information() { :; }
write_warning() { echo "warning:$*"; }
write_error() { echo "error:$*"; }
apt-get() { echo UNEXPECTED-REAL-INSTALL >&2; return 99; }
software::is_native_package_installed() {
    [[ "$1" == present || -f "$STATE/$1" ]]
}
software::is_native_package_available() {
    echo "check:$1" >> "$STATE/events"
    [[ "$1" != absent && "$1" != present ]]
}
sudo() {
    local package="${!#}"
    echo "install:$package" >> "$STATE/events"
    [[ "$package" != broken ]] || return 23
    [[ "$package" != ignored ]] || return 0
    touch "$STATE/$package"
}
""" + library_function('software::add_native_package') + library_function(
                'software::check_native_package_dependency'
            ) + '\n' + request + '\necho FINISHED\n'
            result = subprocess.run(
                ['bash', '-c', source], text=True, capture_output=True, timeout=5,
                env={**os.environ, 'STATE': directory, 'TERMUITXT': 'nocolor'},
            )
            record = root / 'events'
            return result, record.read_text() if record.exists() else ''

    def test_optional_requests_warn_and_continue_after_missing_and_failed_packages(self):
        result, events = self.run_request(
            'software::add_native_package present absent broken good'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('FINISHED', result.stdout)
        self.assertIn("warning:Package 'absent' is not available", result.stdout)
        self.assertNotIn('error:', result.stdout)
        self.assertEqual(events.splitlines(), [
            'check:absent', 'check:broken', 'install:broken', 'check:good', 'install:good',
        ])

    def test_required_unavailable_package_fails_before_install(self):
        result, events = self.run_request('software::check_native_package_dependency absent')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('FINISHED', result.stdout)
        self.assertIn("Required package dependency 'absent' is unavailable", result.stdout)
        self.assertEqual(events.splitlines(), ['check:absent'])

    def test_dependency_verifies_installed_state_after_best_effort_install(self):
        for package, success in (('present', True), ('good', True),
                                 ('broken', False), ('ignored', False)):
            with self.subTest(package=package):
                result, events = self.run_request(
                    'software::check_native_package_dependency ' + package
                )
                self.assertEqual(result.returncode == 0, success, result.stderr)
                self.assertEqual('FINISHED' in result.stdout, success)
                if package == 'present':
                    self.assertEqual(events, '')

    def test_missing_arguments_are_still_an_error(self):
        for helper in ('software::add_native_package',
                       'software::check_native_package_dependency'):
            with self.subTest(helper=helper):
                result, events = self.run_request(helper)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('FINISHED', result.stdout)
                self.assertEqual(events, '')


if __name__ == '__main__':
    unittest.main()
