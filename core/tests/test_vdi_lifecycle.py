#!/usr/bin/env python3
"""Verify stage-two reseal/power transitions without changing a running VM."""

from __future__ import annotations

import os
import pty
import signal
import time
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_oem_themes import library_function


CORE = Path(__file__).resolve().parents[1]


class VdiLifecycleTests(unittest.TestCase):
    def test_unattended_reboot_check_never_prompts_even_with_terminal(self):
        for policy, mode in (
            ({'RTD_NONINTERACTIVE': '1'}, ''),
            ({'DEBIAN_FRONTEND': 'noninteractive'}, ''),
            ({'RTD_NONINTERACTIVE': '1'}, '--dialog'),
            ({'DEBIAN_FRONTEND': 'noninteractive'}, '--dialog'),
            ({}, '--dialog'),
        ):
            with self.subTest(policy=policy, mode=mode), tempfile.TemporaryDirectory() as directory:
                required = Path(directory) / 'reboot-required'
                required.touch()
                function = library_function('software::offer_reboot_if_required').replace(
                    '/var/run/reboot-required', str(required)
                )
                script = """
write_information() { echo "$*"; }
write_warning() { :; }
write_status() { :; }
dialog::prompt_yes_no() { echo PROMPT; return 1; }
reboot() { echo UNEXPECTED-REBOOT; return 1; }
""" + function + '\nsoftware::offer_reboot_if_required ' + mode
                primary, terminal = pty.openpty()
                try:
                    result = subprocess.run(
                        ['bash', '-c', script], stdin=terminal, capture_output=True,
                        text=True, timeout=3,
                        env={**os.environ, 'RTD_NONINTERACTIVE': '0',
                             'DEBIAN_FRONTEND': '', **policy},
                    )
                finally:
                    os.close(primary)
                    os.close(terminal)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn('UNEXPECTED-REBOOT', result.stdout)
                self.assertEqual('PROMPT' in result.stdout, not bool(policy))
                if policy:
                    self.assertIn('deferred to the automated workflow', result.stdout)

    def test_debian_install_watcher_survives_launcher_hangup(self):
        builder = library_function('kvm::make_vm_now_from_debian_org')
        launch = builder[builder.index('\tnohup '):builder.index(
            '\n\tkvm::wait_for_domain_definition'
        )]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            worker = root / 'virt-install'
            # Model virt-install's two phases: installer followed by disk boot.
            worker.write_text(
                '#!/bin/bash\nprintf "%s\\n" "$@" > "$RECORD.args"\n'
                'echo installer > "$RECORD"\nsleep .3\necho disk-boot >> "$RECORD"\n'
            )
            worker.chmod(0o755)
            record = root / 'events'
            process = subprocess.Popen(
                ['bash', '-c', launch + '\nsleep 5'],
                env={**os.environ, 'bin_virt_install': str(worker),
                     '_LOGFILE': str(root / 'log'), 'RECORD': str(record)},
                start_new_session=True, stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                for _ in range(100):
                    if record.exists():
                        break
                    time.sleep(.01)
                self.assertTrue(record.exists())
                os.killpg(process.pid, signal.SIGHUP)
                process.wait(timeout=2)
                for _ in range(100):
                    if 'disk-boot' in record.read_text():
                        break
                    time.sleep(.01)
                self.assertEqual(record.read_text().splitlines(), ['installer', 'disk-boot'])
                args = (root / 'events.args').read_text().splitlines()
                self.assertIn('--wait=-1', args)
                self.assertIn('qemu:///system', args)
                self.assertNotIn('--noreboot', args)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()

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

    def test_kubuntu_reseal_arms_graphical_frontend_without_starting_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            frontend = root / 'usr/lib/ubiquity/ubiquity/frontend/gtk_ui.py'
            frontend.parent.mkdir(parents=True)
            frontend.touch()
            for command in ('X', 'ubiquity-dm'):
                binary = root / 'usr/bin' / command
                binary.parent.mkdir(parents=True, exist_ok=True)
                binary.touch()
                binary.chmod(0o755)
            function = library_function('system::rtd_oem_reseal::_prepare_ubuntu_graphical')
            for path in ('/etc/systemd', '/var/lib/oem-config', '/usr/lib/ubiquity', '/usr/bin'):
                function = function.replace(path, f'{root}{path}')
            script = '''
write_error() { echo "$*" >&2; }
software::add_native_package() { echo "packages:$*"; }
debconf-set-selections() { cat >/dev/null; }
systemctl() {
    if [[ "$1" == get-default ]]; then echo oem-config.target;
    else echo "systemctl:$*"; fi
}
oem-config-prepare() { echo "prepare:$*"; }
oem-config-firstboot() { echo UNEXPECTED-WIZARD; return 1; }
system::rtd_oem_reseal::_install_guest_additions() { echo guest-tools; }
''' + function + '\nsystem::rtd_oem_reseal::_prepare_ubuntu_graphical builder virtual\n'
            result = subprocess.run(
                ['bash', '-c', script], text=True, capture_output=True, timeout=5,
                env={**os.environ, '_LOGFILE': str(root / 'log')}, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('packages:oem-config-gtk oem-config-prepare xserver-xorg', result.stdout)
            self.assertNotIn('UNEXPECTED-WIZARD', result.stdout)
            self.assertTrue((root / 'var/lib/oem-config/run').exists())
            self.assertIn('Environment=FRONTEND=gtk_ui', (
                root / 'etc/systemd/system/oem-config.service.d/10-rtd-frontend.conf'
            ).read_text())
            # A Wayland-only image must not be marked ready if the X server
            # dependency was unavailable, even when package installation returned 0.
            (root / 'usr/bin/X').unlink()
            (root / 'var/lib/oem-config/run').unlink()
            failed = subprocess.run(
                ['bash', '-c', script], text=True, capture_output=True, timeout=5,
                env={**os.environ, '_LOGFILE': str(root / 'log')}, check=False,
            )
            self.assertNotEqual(failed.returncode, 0)
            self.assertIn('requires ubiquity-dm and an Xorg server', failed.stderr)
            self.assertFalse((root / 'var/lib/oem-config/run').exists())


if __name__ == '__main__':
    unittest.main()
