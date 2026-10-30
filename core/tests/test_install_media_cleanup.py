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
            "kvm::clone_template_vm::_remove_install_media_from_config() {", 1
        )[1].split("kvm::clone_template_vm::_clone_from_category() {", 1)[0]
        cls.ubuntu_builder = cls.library.split(
            "kvm::make_vm_now_from_ubuntu_com() {", 1
        )[1].split("kvm::make_vm_now_from_microsoft() {", 1)[0]

    def _run_cleanup(self) -> list[str]:
        function_source = (
            "kvm::clone_template_vm::_remove_install_media_from_config() {"
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
                        detach-disk) return 0 ;;
                    esac
                }}
                {function_source}
                kvm::clone_template_vm::_remove_install_media_from_config Test_VM
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

    def test_cleanup_only_removes_persistent_media_definitions(self):
        calls = self._run_cleanup()
        self.assertIn("dumpxml Test_VM --inactive", calls)
        self.assertIn("detach-disk Test_VM sda --config", calls)
        self.assertIn("detach-disk Test_VM sdb --config", calls)
        self.assertFalse(any("vda" in call and "detach-disk" in call for call in calls))
        self.assertFalse(any(call.startswith("change-media ") for call in calls))
        self.assertFalse(any("--live" in call for call in calls))

    def test_modern_ubuntu_paths_remove_media_after_domain_definition(self):
        self.assertEqual(
            self.ubuntu_builder.count("--wait=-1 --noreboot --noautoconsole"), 3
        )
        self.assertEqual(
            self.ubuntu_builder.count(
                'kvm::clone_template_vm::_remove_install_media_from_config "${vm_name}"'
            ),
            3,
        )
        self.assertNotIn('virsh start "${vm_name}"', self.ubuntu_builder)
        definition = 'kvm::wait_for_domain_definition "${vm_name}"'
        cleanup = (
            'kvm::clone_template_vm::_remove_install_media_from_config "${vm_name}"'
        )
        sections = self.ubuntu_builder.split(cleanup)
        self.assertEqual(len(sections), 4)
        for section in sections[:-1]:
            definition_position = section.rfind(definition)
            installer_position = section.rfind("--wait=-1 --noreboot --noautoconsole")
            self.assertGreater(definition_position, installer_position)


if __name__ == "__main__":
    unittest.main()
