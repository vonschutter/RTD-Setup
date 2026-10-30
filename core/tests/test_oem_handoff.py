#!/usr/bin/env python3
"""Regression tests for RTD's native Ubuntu Wayland first-user handoff."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


CORE = Path(__file__).resolve().parents[1]
LIBRARY = CORE / "_rtd_library"
FINALIZER = CORE / "rtd-vm-template-finalize-linux.sh"


class UbuntuOemHandoffTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.library = LIBRARY.read_text()
        cls.finalizer = FINALIZER.read_text()

    def test_library_has_valid_shell_syntax(self):
        completed = subprocess.run(
            ["bash", "-n", str(LIBRARY)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_uses_gdm_gnome_initial_setup_not_legacy_ubiquity(self):
        self.assertIn(
            'software::add_native_package "gnome-initial-setup"',
            self.library,
        )
        self.assertIn("/usr/share/gnome-session/sessions/gnome-initial-setup.session", self.library)
        self.assertIn("InitialSetupEnable=True", self.library)
        prepare = self.library.split(
            "system::rtd_oem_reseal::_prepare_ubuntu_like() {", 1
        )[1].split("system::rtd_oem_reseal::_prepare_debian() {", 1)[0]
        self.assertNotIn("oem-config-prepare --quiet", prepare)
        self.assertNotIn('software::add_native_package "oem-config-gtk"', prepare)

    def test_build_account_is_recovery_user_not_oem_user(self):
        self.assertIn('usermod --uid 29998 "\\$build_user"', self.library)
        self.assertIn('groupmod --gid 29998 "\\$build_group"', self.library)
        self.assertNotIn('usermod --uid 29999 "\\$build_user"', self.library)

    def test_recovery_account_is_hidden_then_removed_after_uid_1000_login(self):
        self.assertIn("SystemAccount=true", self.library)
        linux_config = (CORE / "rtd-oem-linux-config.sh").read_text()
        self.assertIn("getent passwd 29998", linux_config)
        self.assertIn('userdel --force --remove "${recovery_user}"', linux_config)
        self.assertIn('== "1000"', linux_config)
        self.assertNotIn("_stage_ubuntu_oem_user", self.library)
        self.assertNotIn("rtd-prepare-oem-temporary-user.service", self.library)

    def test_reseal_requires_uid_1000_to_be_free(self):
        self.assertIn("getent passwd 1000", self.library)
        self.assertIn("it must remain available for GNOME Initial Setup", self.library)

    def test_poweroff_uses_logged_systemd_request_and_fallback(self):
        self.assertIn(
            '"${_systemctl_bin}" --no-block --check-inhibitors=no poweroff',
            self.library,
        )
        self.assertNotIn('"${_systemctl_bin}" --force poweroff', self.library)
        self.assertIn('"${_shutdown_bin}" -P now', self.library)
        self.assertIn('>>"${_LOGFILE}" 2>&1', self.library)

    def test_spice_agent_uses_one_session_launcher(self):
        integration = self.library.split(
            "system::rtd_oem_reseal::_install_guest_additions() {", 1
        )[1].split("system::rtd_oem_reseal::_prepare_ubuntu_like() {", 1)[0]
        self.assertIn("/usr/lib/systemd/user/spice-vdagent.service", integration)
        self.assertIn("Hidden=true", integration)
        self.assertIn("X-GNOME-Autostart-enabled=false", integration)
        self.assertIn('pkill -u "${_session_uid}" -x spice-vdagent', integration)
        self.assertIn("systemctl --user start spice-vdagent.service", integration)
        self.assertIn("Hidden=false", integration)
        self.assertNotIn(
            "echo -e \"[Desktop Entry]\\nType=Application\\nExec=/usr/bin/spice-vdagent",
            self.library,
        )

    def test_finalizer_separates_oem_readiness_from_poweroff_failure(self):
        self.assertIn("system::rtd_oem_reseal --prepare-only", self.finalizer)
        self.assertIn(
            'write_status "reseal" "ready" "OEM preparation completed successfully;',
            self.finalizer,
        )
        self.assertIn(
            'write_status "poweroff" "failed" "OEM preparation completed, but',
            self.finalizer,
        )


if __name__ == "__main__":
    unittest.main()
