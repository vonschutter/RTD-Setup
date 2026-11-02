#!/usr/bin/env python3
"""Exercise generated Ubuntu server-media late-commands without provisioning."""

from __future__ import annotations

import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path


LIBRARY = Path(__file__).resolve().parents[1] / "_rtd_library"


class CloudConfigTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = LIBRARY.read_text()
        cls.generator = "template::cloud_config() {" + source.split(
            "template::cloud_config() {", 1
        )[1].split("template::minecraft_server_launcher() {", 1)[0]

    def generate(self, role: str, app: str, document=False) -> list[str] | str:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "user-data"
            script = """
system::log_item() { :; }
kvm::util::set_vm_name() { printf -v "$2" '%s' "$4"; }
""" + self.generator + """
template::cloud_config --vmname Test_VM --write "$1" --role "$2" --server-app "$3"
"""
            completed = subprocess.run(
                ["bash", "-c", script, "test", str(output), role, app],
                env={
                    **os.environ,
                    "Preference_InitialUser": "builder",
                    "Preference_InitialUserPassword": "test-placeholder",
                    "Preference_InitialKeyboardLayout": "se",
                    "Preference_ssh_pub_key": "ssh-ed25519 fixture test",
                    "Preference_DiskEncryption": "NO",
                    "GIT_RTD_SRC_URL": "https://example.invalid/RTD-Setup.git",
                    "_OEM_DIR": "/opt/rtd",
                },
                text=True, capture_output=True, check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            if document:
                return output.read_text()
            return [
                line.strip()[2:]
                for line in output.read_text().splitlines()
                if line.strip().startswith("- ") and "curtin in-target" in line
            ]

    def test_installer_explicitly_reboots_into_installed_system(self):
        document = self.generate("VDI", "kubuntu-desktop", document=True)
        self.assertIn("autoinstall:\n    version: 1\n    shutdown: reboot", document)
        # Subiquity owns the install reboot; a separate cloud-init power action
        # in the live environment must not race the installer or stage two.
        self.assertNotIn("\npower_state:", document)

    def test_target_commands_isolate_mounts_for_desktops_and_servers(self):
        cases = [
            ("VDI", app) for app in (
                "kubuntu-desktop", "ubuntu-desktop", "xubuntu-desktop",
                "ubuntu-mate-desktop", "lubuntu-desktop",
                "cinnamon-desktop-environment",
            )
        ] + [("server", ""), ("server", "openssh-server"), ("minecraft", "")]
        expected = [
            "unshare", "--mount", "--propagation", "private", "--",
            "curtin", "in-target", "--target=/target", "--",
        ]
        for role, app in cases:
            with self.subTest(role=role, app=app):
                commands = self.generate(role, app)
                self.assertTrue(commands)
                for command in commands:
                    args = shlex.split(command)
                    self.assertEqual(args[:len(expected)], expected)
                    # Parse the inner script too: bash -n on the library cannot
                    # detect syntax errors hidden inside generated heredocs.
                    if "-c" in args or "-ec" in args:
                        index = args.index("-c") if "-c" in args else args.index("-ec")
                        if args[index + 1].startswith(("bash /opt/rtd/core/rtd-oem-enable-config.sh", "/opt/rtd/core/rtd-oem-enable-config.sh")):
                            self.assertNotIn('; exit 0', args[index + 1])
                        result = subprocess.run(
                            ["bash", "-n", "-c", args[index + 1]],
                            text=True, capture_output=True, check=False,
                        )
                        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
