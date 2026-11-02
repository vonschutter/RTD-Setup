#!/usr/bin/env python3
"""Verify stage-two reseal/power transitions without changing a running VM."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_oem_themes import library_function


CORE = Path(__file__).resolve().parents[1]


class VdiLifecycleTests(unittest.TestCase):
    def test_shutdown_requires_successful_bundles_and_reseal(self):
        name = 'rtd_template_finalize::run_finalization_tasks'
        function = name + '() {' + (CORE / 'rtd-vm-template-finalize-linux.sh').read_text().split(
            name + '() {', 1
        )[1].split('\n}\n', 1)[0] + '\n}\n'
        for bundle_result, reseal_result in ((0, 0), (13, 0), (0, 17)):
            with self.subTest(bundle=bundle_result, reseal=reseal_result), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                bundle = root / 'modules/oem-bundle-manager.mod/rtd-oem-bundle-manager'
                bundle.parent.mkdir(parents=True)
                bundle.write_text(f'#!/bin/bash\nexit {bundle_result}\n')
                bundle.chmod(0o755)
                marker = root / 'auto-finalize'
                marker.touch()
                record = root / 'events'
                script = '''
rtd_template_finalize::supported() { return 0; }
rtd_template_finalize::full_software_update() { echo update >> "$RECORD"; }
rtd_template_finalize::write_status() { printf '%s:%s\\n' "$1" "$2" >> "$RECORD"; }
rtd_template_finalize::configure_post_oobe_bundle_manager() { echo post-oobe >> "$RECORD"; }
rtd_template_finalize::disable_temporary_oem_autologin() { echo disable-autologin >> "$RECORD"; }
system::rtd_oem_reseal() { echo "reseal:$*" >> "$RECORD"; return "$RESEAL_RESULT"; }
system::rtd_oem_reseal::_virtualization_context() { echo virtual; }
system::rtd_oem_reseal::_finalize_shutdown() { echo poweroff >> "$RECORD"; }
''' + function + '\nrtd_template_finalize::run_finalization_tasks\n'
                result = subprocess.run(
                    ['bash', '-c', script], text=True, capture_output=True, timeout=5,
                    env={**os.environ, '_OEM_DIR': directory, '_LOGFILE': str(root / 'log'),
                         'RTD_TEMPLATE_AUTOFINALIZE_MARKER': str(marker), 'RECORD': str(record),
                         'RESEAL_RESULT': str(reseal_result)}, check=False,
                )
                events = record.read_text().splitlines()
                if bundle_result or reseal_result:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn('poweroff', events)
                    self.assertTrue(marker.exists())
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertFalse(marker.exists())
                    self.assertLess(events.index('reseal:--prepare-only'), events.index('reseal:ready'))
                    self.assertLess(events.index('reseal:ready'), events.index('poweroff'))
                    self.assertEqual(events.count('poweroff'), 1)

    def test_kubuntu_reseal_arms_packaged_text_frontend_without_starting_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            frontend = root / 'usr/lib/ubiquity/ubiquity/frontend/debconf_ui.py'
            frontend.parent.mkdir(parents=True)
            frontend.touch()
            function = library_function('system::rtd_oem_reseal::_prepare_ubuntu_text')
            for path in ('/etc/systemd', '/var/lib/oem-config', '/usr/lib/ubiquity'):
                function = function.replace(path, f'{root}{path}')
            script = '''
software::add_native_package() { echo "packages:$*"; }
debconf-set-selections() { cat >/dev/null; }
systemctl() {
    if [[ "$1" == get-default ]]; then echo oem-config.target;
    else echo "systemctl:$*"; fi
}
oem-config-prepare() { echo "prepare:$*"; }
oem-config-firstboot() { echo UNEXPECTED-WIZARD; return 1; }
system::rtd_oem_reseal::_install_guest_additions() { echo guest-tools; }
''' + function + '\nsystem::rtd_oem_reseal::_prepare_ubuntu_text builder virtual\n'
            result = subprocess.run(
                ['bash', '-c', script], text=True, capture_output=True, timeout=5,
                env={**os.environ, '_LOGFILE': str(root / 'log')}, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('packages:oem-config-debconf oem-config-prepare', result.stdout)
            self.assertNotIn('UNEXPECTED-WIZARD', result.stdout)
            self.assertTrue((root / 'var/lib/oem-config/run').exists())
            self.assertIn('Environment=FRONTEND=debconf_ui', (
                root / 'etc/systemd/system/oem-config.service.d/10-rtd-frontend.conf'
            ).read_text())


if __name__ == '__main__':
    unittest.main()
