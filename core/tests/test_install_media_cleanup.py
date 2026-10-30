#!/usr/bin/env python3
"""Regression tests for removing installer and NoCloud media after VM installation."""

from __future__ import annotations

import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


CORE = Path(__file__).resolve().parents[1]
LIBRARY = CORE / "_rtd_library"


class InstallMediaCleanupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.library = LIBRARY.read_text()
        cls.cleanup_function = cls.library.split(
            "kvm::clone_template_vm::_detach_install_media() {", 1
        )[1].split("kvm::clone_template_vm::_clone_from_category() {", 1)[0]
        cls.ubuntu_builder = cls.library.split(
            "kvm::make_vm_now_from_ubuntu_com() {", 1
        )[1].split("kvm::make_vm_now_from_microsoft() {", 1)[0]

    def _run_cleanup(self, state: str) -> list[str]:
        function_source = (
            "kvm::clone_template_vm::_detach_install_media() {"
            + self.cleanup_function
        )
        with tempfile.TemporaryDirectory() as temporary_directory:
            calls = Path(temporary_directory) / "virsh.calls"
            script = textwrap.dedent(
                f"""
                write_warning() {{ :; }}
                write_information() {{ :; }}
                write_status() {{ :; }}
                virsh() {{
                    printf '%s\\n' "$*" >> {calls!s}
                    case "$1" in
                        dumpxml)
                            printf '%s\\n' \
                                "<domain><devices>" \
                                "<disk type='file' device='disk'><target dev='vda' bus='virtio'/></disk>" \
                                "<disk type='file' device='cdrom'><target dev='sda' bus='sata'/></disk>" \
                                "<disk type='file' device='cdrom'><target dev='sdb' bus='sata'/></disk>" \
                                "</devices></domain>"
                            ;;
                        domstate) printf '%s\\n' {state!r} ;;
                        change-media|detach-disk) return 0 ;;
                    esac
                }}
                {function_source}
                kvm::clone_template_vm::_detach_install_media Test_VM
                """
            )
            completed = subprocess.run(
                ["bash", "-c", script],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            return calls.read_text().splitlines()

    def test_running_vm_ejects_both_isos_live_and_removes_both_definitions(self):
        calls = self._run_cleanup("running")
        self.assertIn("change-media Test_VM sda --eject --live --force", calls)
        self.assertIn("change-media Test_VM sdb --eject --live --force", calls)
        self.assertIn("detach-disk Test_VM sda --config", calls)
        self.assertIn("detach-disk Test_VM sdb --config", calls)
        self.assertFalse(any("vda" in call and "detach-disk" in call for call in calls))

    def test_inactive_vm_only_removes_persistent_media_definitions(self):
        calls = self._run_cleanup("shut off")
        self.assertFalse(any(call.startswith("change-media ") for call in calls))
        self.assertIn("detach-disk Test_VM sda --config", calls)
        self.assertIn("detach-disk Test_VM sdb --config", calls)

    def test_modern_ubuntu_paths_wait_for_install_then_cleanup_media(self):
        self.assertEqual(
            self.ubuntu_builder.count("--wait=-1 --noreboot --noautoconsole"), 3
        )
        self.assertEqual(
            self.ubuntu_builder.count(
                'kvm::clone_template_vm::_detach_install_media "${vm_name}"'
            ),
            3,
        )
        self.assertEqual(self.ubuntu_builder.count('virsh start "${vm_name}"'), 3)


if __name__ == "__main__":
    unittest.main()
