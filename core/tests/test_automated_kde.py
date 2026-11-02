#!/usr/bin/env python3
"""Exercise unattended dependency checks and Plasma 6 OEM configuration."""

from __future__ import annotations

import configparser
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_oem_themes import library_function

try:
    import yaml
except ImportError:
    yaml = None


class AutomatedKdeTests(unittest.TestCase):
    def run_shell(self, source, env=None):
        return subprocess.run(
            ["/bin/bash", "-c", source], env={**os.environ, **(env or {})},
            text=True, capture_output=True, timeout=5, check=False,
        )

    def test_automated_dependency_checks_do_not_prompt(self):
        source = """
write_status() { :; }
write_error() { echo "$*" >&2; }
read() { echo UNEXPECTED-PROMPT >&2; return 1; }
system::detect_session() { echo GUI; }
zenity() { echo UNEXPECTED-PROMPT >&2; return 1; }
system::install_missing_commands() { printf 'install:%s:%s\\n' "$*" "$DEBIAN_FRONTEND"; }
""" + library_function("dependency::command_exists") + """
dependency::command_exists rtd-test-missing-dependency
"""
        for policy in ({"RTD_NONINTERACTIVE": "1", "DEBIAN_FRONTEND": ""},
                       {"RTD_NONINTERACTIVE": "0", "DEBIAN_FRONTEND": "noninteractive"}):
            with self.subTest(policy=policy):
                result = self.run_shell(source, policy)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("install:rtd-test-missing-dependency:noninteractive", result.stdout)
                self.assertNotIn("UNEXPECTED-PROMPT", result.stderr)

    def test_automatic_install_uses_noninteractive_sudo_and_propagates_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            sudo = Path(directory) / "sudo"
            sudo.write_text('#!/bin/sh\nprintf "sudo:%s\\n" "$*"\nexit 29\n')
            sudo.chmod(0o755)
            source = """
write_status() { :; }
write_error() { :; }
system::install_missing_commands() { sudo install-command "$@"; }
""" + library_function("dependency::command_exists") + """
dependency::command_exists rtd-test-missing-dependency
"""
            result = self.run_shell(source, {"RTD_NONINTERACTIVE": "1", "PATH": directory})
            self.assertEqual(result.returncode, 29)
            self.assertIn("sudo:-n install-command rtd-test-missing-dependency", result.stdout)

    def test_sddm_autologin_overrides_kubuntu_defaults_and_selects_wayland(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            configs = root / "etc/sddm.conf.d"
            configs.mkdir(parents=True)
            (configs / "20-kubuntu.conf").write_text('[Autologin]\nSession=plasma\nUser=\n')
            sessions = root / "usr/share/wayland-sessions"
            sessions.mkdir(parents=True)
            (sessions / "plasma.desktop").touch()
            source = """
write_status() { :; }
write_warning() { :; }
write_error() { echo "$*" >&2; }
""" + library_function("system::toggle_oem_auto_login").replace(
                "/etc/", f"{root}/etc/"
            ).replace("/usr/share/", f"{root}/usr/share/") + """
system::toggle_oem_auto_login --enable
"""
            result = self.run_shell(source, {"_OEM_USER": "builder", "_TLA": "rtd", "RTD_OEM_SESSION": ""})
            self.assertEqual(result.returncode, 0, result.stderr)
            config = configparser.ConfigParser()
            config.read(sorted(str(path) for path in configs.glob("*.conf")))
            self.assertEqual(config["Autologin"]["User"], "builder")
            self.assertEqual(config["Autologin"]["Session"], "plasma.desktop")

    def test_plasma6_uses_qt6_tools_and_icon_config_fallback_without_installing(self):
        source = """
write_status() { :; }
write_error() { echo "$*" >&2; }
dependency::command_exists() { echo UNEXPECTED-INSTALL >&2; return 1; }
realpath() { echo '/wallpaper image.jpg'; }
file() { echo image/jpeg; }
qdbus6() { printf 'qdbus6:%s\\n' "$*"; }
kwriteconfig6() { printf 'kwriteconfig6:%s\\n' "$*"; }
""" + library_function("kde::_kwriteconfig_cmd") + library_function(
            "kde::set_wallpaper"
        ) + library_function("kde::set_icon_theme") + """
kde::set_wallpaper '/wallpaper image.jpg' || exit $?
kde::set_icon_theme --theme breeze-dark
"""
        result = self.run_shell(source, {"PATH": "/nonexistent", "XDG_RUNTIME_DIR": "/run/user/1000"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("qdbus6:org.kde.plasmashell", result.stdout)
        self.assertIn("d.wallpaperPlugin = 'org.kde.image'", result.stdout)
        self.assertIn("kwriteconfig6:--file kscreenlockerrc", result.stdout)
        self.assertIn("kwriteconfig6:--file kdeglobals --group Icons --key Theme breeze-dark", result.stdout)
        self.assertNotIn("UNEXPECTED-INSTALL", result.stderr)

    @unittest.skipUnless(yaml, "Netplan tests require PyYAML")
    def test_network_preparation_preserves_server_addressing_without_live_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            configs = root / "etc/netplan"
            configs.mkdir(parents=True)
            original = configs / "50-cloud-init.yaml"
            original_text = """network:
  version: 2
  ethernets:
    enp1s0:
      renderer: networkd
      addresses: [192.0.2.10/24]
      routes: [{to: default, via: 192.0.2.1}]
      nameservers: {addresses: [192.0.2.53]}
      match: {macaddress: '52:54:00:11:22:33'}
      set-name: enp1s0
"""
            original.write_text(original_text)
            function = library_function("system::prepare_ubuntu_desktop_networking")
            # Exercise file generation as an unprivileged test user, in a sandbox.
            function = function.replace('[[ $EUID -eq 0 ]]', 'true')
            for path in ("/etc/netplan", "/lib/netplan", "/run/netplan"):
                function = function.replace(path, f"{root}{path}")
            source = """
write_error() { echo "$*" >&2; }
write_status() { :; }
netplan() { echo "netplan:$*"; }
systemctl() { echo "systemctl:$*"; }
""" + function + "\nsystem::prepare_ubuntu_desktop_networking\n"
            result = self.run_shell(source)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(original.read_text(), original_text)
            target = configs / "99-rtd-network-manager.yaml"
            override = yaml.safe_load(target.read_text())["network"]
            self.assertEqual(override["renderer"], "NetworkManager")
            self.assertEqual(override["ethernets"]["enp1s0"], {"renderer": "NetworkManager"})
            self.assertNotIn("netplan:apply", result.stdout)
            self.assertNotIn("systemctl:stop", result.stdout)
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
            # Live handoff must restore NM addressing after networkd removes it.
            live = source.replace(
                "\nsystem::prepare_ubuntu_desktop_networking\n",
                '''
nmcli() {
    if [[ "$1" == -t ]]; then echo 'test-uuid:netplan-enp1s0';
    else echo "nmcli:$*"; fi
}
system::prepare_ubuntu_desktop_networking --apply
''',
            )
            applied = self.run_shell(live)
            self.assertEqual(applied.returncode, 0, applied.stderr)
            self.assertIn("netplan:apply", applied.stdout)
            self.assertIn("nmcli:--wait 30 connection up uuid test-uuid", applied.stdout)
            # Validation failure must restore a previous override and report failure.
            prior = target.read_text()
            failure = self.run_shell(source.replace('echo "netplan:$*";', 'return 1;'))
            self.assertNotEqual(failure.returncode, 0)
            self.assertEqual(target.read_text(), prior)

    def test_global_theme_uses_plasma6_package_ids(self):
        source = """
write_error() { echo "$*" >&2; }
plasma-apply-lookandfeel() {
    if [[ "$1" == --list ]]; then echo org.kde.breezedark.desktop;
    else printf 'apply:%s\\n' "$*"; fi
}
""" + library_function("kde::set_global_look_and_feel") + """
kde::set_global_look_and_feel --package Breeze-Dark
"""
        result = self.run_shell(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("apply:--apply org.kde.breezedark.desktop", result.stdout)

    def test_fonts_create_a_konsole_profile_on_a_fresh_account(self):
        with tempfile.TemporaryDirectory() as directory:
            tools = Path(directory) / "bin"
            tools.mkdir()
            writer = tools / "kwriteconfig6"
            writer.write_text('''#!/usr/bin/python3
import configparser, os, sys
from pathlib import Path
a = sys.argv
path = Path(a[a.index('--file') + 1])
if not path.is_absolute(): path = Path(os.environ['HOME']) / '.config' / path
group, key, value = a[a.index('--group')+1], a[a.index('--key')+1], a[-1]
c = configparser.ConfigParser()
c.read(path)
if not c.has_section(group): c.add_section(group)
c[group][key] = value
path.parent.mkdir(parents=True, exist_ok=True)
with path.open('w') as f: c.write(f)
''')
            writer.chmod(0o755)
            source = """
write_error() { echo "$*" >&2; }
fc-list() { echo 'SauceCodePro Nerd Font'; }
""" + library_function("kde::_kwriteconfig_cmd") + library_function("kde::set_font_preferences") + """
kde::set_font_preferences && kde::set_font_preferences
"""
            result = self.run_shell(source, {
                "HOME": directory, "PATH": f"{tools}:{os.environ['PATH']}",
                "XDG_DATA_HOME": f"{directory}/.local/share",
            })
            self.assertEqual(result.returncode, 0, result.stderr)
            config = configparser.ConfigParser()
            config.read(Path(directory) / ".config/konsolerc")
            self.assertEqual(config["Desktop Entry"]["DefaultProfile"], "RTD.profile")
            profile = configparser.ConfigParser()
            profile.read(Path(directory) / ".local/share/konsole/RTD.profile")
            self.assertTrue(profile["Appearance"]["Font"].startswith("SauceCodePro Nerd Font,12,"))


if __name__ == "__main__":
    unittest.main()
