#!/usr/bin/env python3
"""Regression tests for unattended OEM theme installation."""

from __future__ import annotations

import os
import pty
import subprocess
import tempfile
import unittest
from pathlib import Path


CORE = Path(__file__).resolve().parents[1]


def library_function(name: str) -> str:
    return name + "() {" + (CORE / "_rtd_library").read_text().split(
        name + "() {", 1
    )[1].split("\n}\n", 1)[0] + "\n}\n"


class OemThemeTests(unittest.TestCase):
    def test_wallpaper_replacement_never_prompts_on_a_terminal(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wallpapers = root / "wallpapers with spaces"
            wallpapers.mkdir()
            (wallpapers / "test image.jpg").touch()
            destination = root / "registry"
            destination.mkdir()
            registry = destination / "oem-backgrounds.xml"
            registry.write_text("old registry")
            sentinel = root / "oem-backgrounds.xml"
            sentinel.write_text("unrelated working file")
            function = library_function("oem::register_wallpapers_for_gnome").replace(
                '/usr/share/gnome-background-properties', str(destination)
            )
            primary, terminal = pty.openpty()
            try:
                for _ in range(2):
                    registry.chmod(0o444)
                    result = subprocess.run(
                        ["bash", "-c", function + '\noem::register_wallpapers_for_gnome "$1"',
                         "test", str(wallpapers)],
                        stdin=terminal, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                        cwd=root, text=True, timeout=5, check=False,
                        env={**os.environ, "TMPDIR": directory},
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn(str(wallpapers / "test image.jpg"), registry.read_text())
                    self.assertEqual(registry.stat().st_mode & 0o777, 0o644)
                    self.assertEqual(sentinel.read_text(), "unrelated working file")
                    self.assertEqual(list(root.glob("rtd-backgrounds.*")), [])
            finally:
                os.close(primary)
                os.close(terminal)

    def test_wallpaper_install_failure_is_reported_and_tempfile_removed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "bin"
            tools.mkdir()
            installer = tools / "install"
            installer.write_text("#!/bin/sh\nexit 23\n")
            installer.chmod(0o755)
            function = library_function("oem::register_wallpapers_for_gnome").replace(
                '/usr/share/gnome-background-properties', str(root / "registry")
            )
            result = subprocess.run(
                ["bash", "-c", function + '\noem::register_wallpapers_for_gnome "$1"',
                 "test", directory],
                env={**os.environ, "TMPDIR": directory, "PATH": f"{tools}:{os.environ['PATH']}"},
                text=True, capture_output=True, timeout=5, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("registered successfully", result.stdout)
            self.assertEqual(list(root.glob("rtd-backgrounds.*")), [])

    def test_recipe_keeps_system_installation_out_of_user_phase(self):
        recipe = "recipe:_OEM:_Themes_and_Tweaks () {" + (
            CORE / "_rtd_recipies.info"
        ).read_text().split("recipe:_OEM:_Themes_and_Tweaks () {", 1)[1].split("\n}\n", 1)[0] + "\n}\n"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            themes = root / "themes with spaces"
            themes.mkdir()
            (themes / "plus-themes.sh").write_text(
                '#!/bin/bash\n'
                '[[ "$DEBIAN_FRONTEND" == noninteractive && "$GIT_TERMINAL_PROMPT" == 0 ]] || exit 2\n'
                'read -r answer && exit 3\n'
                'printf "themes\\n" >> "$TEST_RECORD"\n'
            )
            script = """
write_status() { :; }
write_information() { :; }
write_error() { echo "$*" >&2; }
recipe:_ADM:_Compression_Tools() { :; }
security::enable_firewall() { :; }
oem::rtd_tools_make_launchers() { :; }
oem::check_boot_splash_screen_enable() { :; }
system::tune_system_power_profile() { :; }
system::distribution_type() { echo debian; }
software::add_native_package() { :; }
software::add_gnome_extensions() { :; }
ps() { echo gnome-shell; }
snap() { :; }
oem::register_wallpapers_for_gnome() { echo registry >> "$TEST_RECORD"; }
system::run_command_in_gnome_user_session() {
    cat "$2" > "$TEST_USER_SCRIPT"
    echo user >> "$TEST_RECORD"
}
""" + recipe + "\nrecipe:_OEM:_Themes_and_Tweaks\n"
            record = root / "calls"
            user_script = root / "user.sh"
            result = subprocess.run(
                ["bash", "-c", script], text=True, capture_output=True, timeout=5,
                env={**os.environ, "_THEME_DIR": str(themes), "_OEM_DIR": directory,
                     "_TLA": "rtd-test-no-skeleton", "TEST_RECORD": str(record),
                     "TEST_USER_SCRIPT": str(user_script)}, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(record.read_text().splitlines(), ["themes", "registry", "user"])
            self.assertNotIn("register_wallpapers", user_script.read_text())
            self.assertNotIn("plus-themes.sh", user_script.read_text())

    def test_user_session_recovers_plasma_authorization_from_user_manager(self):
        script = r'''
id() { echo 500; }
sudo() {
    shift 4
    if [[ "$*" == *'systemctl --user show-environment' ]]; then
        printf '%s\n' 'DISPLAY=:2' 'XAUTHORITY=/run/user/500/xauth_desktop' 'UNSAFE=ignored'
    else
        "$@"
    fi
}
SUDO_USER=builder
XAUTHORITY=/root/wrong-auth
''' + library_function("system::run_command_in_gnome_user_session") + r'''
system::run_command_in_gnome_user_session /bin/bash -c '
[[ "$DISPLAY" == :2 && "$XAUTHORITY" == /run/user/500/xauth_desktop && -z "${UNSAFE:-}" ]]'
'''
        result = subprocess.run(['bash', '-c', script], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_user_session_preserves_arguments_and_returns_sudo_failure(self):
        script = """
sudo() { printf '%s\\n' "$@"; return 37; }
id() { echo 1000; }
SUDO_USER=builder
""" + library_function("system::run_command_in_gnome_user_session") + """
system::run_command_in_gnome_user_session /bin/bash '/tmp/theme settings.sh'
"""
        result = subprocess.run(["bash", "-c", script], text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 37)
        self.assertIn("-n", result.stdout.splitlines())
        self.assertIn("/tmp/theme settings.sh", result.stdout.splitlines())


if __name__ == "__main__":
    unittest.main()
