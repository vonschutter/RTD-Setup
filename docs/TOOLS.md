# RTD Tool Reference

[Back to README](../README.md) | [Getting Started](GETTING_STARTED.md) | [Use Cases](USE_CASES.md) | [Modules](../modules/README.md)

This catalog covers the `rtd-*` command entry points shipped in `modules/`. Commands are grouped by the user task they address. Consult the linked module README and built-in help before actions that require privileges or modify disks, networking, security policy, or installed software.

## Maintenance And Support

| Command | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| `rtd-update-system` | Update native packages, Flatpaks, and snaps | `--show` reports today's updates without updating | [System Update](../modules/oem-system-update.mod/README.md) |
| `rtd-update-self` | Update or reinitialize the RTD installation | Backs up and synchronizes `/opt/rtd` | [System Update](../modules/oem-system-update.mod/README.md) |
| `rtd-simple-support-tool` | Menu of common support tasks | Useful in terminal/SSH workflows | [Simple Support](../modules/simple-support-tool.mod/README.md) |
| `rtd-system-hardware-information` | Graphical hardware and sensor dashboard | Uses a desktop UI | [Hardware Information](../modules/system-hardware-information.mod/README.md) |
| `rtd-oem-backup-linux-config` | Encrypted user/configuration backup workflow | Requires chosen destination and passphrase | [User Backup](../modules/system-user-backup.mod/README.md) |

## Software And Desktop Setup

| Command | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| `rtd-oem-bundle-manager` | Add or remove software/configuration bundles | Installs selected software | [Bundle Manager](../modules/oem-bundle-manager.mod/README.md) |
| `rtd-oem-tweaks` | Apply selected GNOME workstation tweaks | Run as the desktop user | [OEM Tweaks](../modules/rtd-oem-tweaks.mod/README.md) |
| `rtd-desktop-look-switcher` | Apply RTD GNOME visual presets | Changes per-user desktop appearance | [Desktop Look Switcher](../modules/rtd-desktop-look-switcher.mod/README.md) |
| `rtd-theme-manager` | Select installed GNOME themes and optional wallpaper | Requires GNOME tooling and Zenity | [Theme Manager](../modules/theme-manager/README.md) |
| `rtd-gnome-shell-extension-installer` | Search for and install GNOME Shell extensions | Modifies installed user/system extensions | [GNOME Extension Installer](../modules/gnome-shell-extension-installer.mod/README.md) |

## Media And Virtualization

| Command | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| `rtd-ventoy-usb` | Create branded Ventoy multi-ISO installation media | Erases the selected device | [Ventoy USB Creator](../modules/oem-ventoy.mod/README.md) |
| `rtd-vm-tool` | Terminal KVM/libvirt VM management tool | Requires KVM/libvirt | [VM Tool](../modules/vm-tool.mod/README.md) |
| `rtd-vm-tool-gtk` | Graphical VM tool interface | Requires desktop session and KVM/libvirt | [VM Tool](../modules/vm-tool.mod/README.md) |
| `rtd-macos-kvm` | Prepare macOS recovery assets and KVM guest definitions | Review licensing and host requirements | [macOS KVM](../modules/macos-kvm.mod/README.md) |
| `rtd-setup-whonix.sh` | Deploy Whonix VMs under KVM/libvirt | Requires root and virtualization | [Whonix](../modules/setup-whonix.mod/README.md) |

## Security And Networking

| Command | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| `rtd-security-tool` | Menu-driven security setup and audit actions | Actions can alter host security configuration | [Security Tool](../modules/Security-tool.mod/README.md) |
| `rtd-check-sec` | Inspect ELF/kernel exploit mitigations | Inspection-oriented command | [Checksec](../modules/rtd-check-sec.mod/README.md) |
| `rtd-start-vpn-router` | Turn a Linux host into a VPN-backed gateway | Modifies routing and firewall rules | [VPN Router](../modules/rtd-vpn-router.mod/README.md) |
| `rtd-nordvpn` | Terminal UI for common NordVPN client actions | Requires a NordVPN account/client | [NordVPN Manager](../modules/nordvpn-manager.mod/README.md) |

## Specialist Utilities

| Command | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| `rtd-oem-app-runner` | Verify, unpack, and run packaged OEM utilities | May launch external payloads | [OEM App Runner](../modules/oem-app-runner.mod/README.md) |
| `rtd-minecraft-server` | Prepare and run a monitored Minecraft server session | Downloads/install dependencies and server software | [Minecraft Server](../modules/minecraft-server-manager.mod/README.md) |
| `rtd-steam-world-of-tanks-utility` | Launch World of Tanks replays and assist with GE-Proton | Steam/gaming workflow | [World of Tanks](../modules/steam-world-of-tanks-utility.mod/README.md) |
| `rtd-steam-world-of-warships-utility` | Launch World of Warships replays and assist with GE-Proton | Steam/gaming workflow | [World of Warships](../modules/steam-world-of-warships-utility.mod/README.md) |
| `rtd-ai-chat` | Launch the bundled command-line AI chat helper | Requires API/client configuration as described by the client | [AI Chat](../modules/rtd-ai-chat.mod/README.md) |

## System Administration Helpers

The commands in `oem-system-admin.mod` are individual convenience entry points. Start with `rtd-script-menu` on a graphical desktop, or run a command directly when its action is understood. See [System Admin Tools](../modules/oem-system-admin.mod/README.md).

| Command | Purpose |
| --- | --- |
| `rtd-script-menu` | Graphical menu for the helper commands in this module |
| `rtd-7z-this`, `rtd-7z-all-files-here` | Create compressed archives |
| `rtd-7z-encrypt-this`, `rtd-7z-encrypt-all-files-here` | Create encrypted compressed archives |
| `rtd-add-ubuntu-to-landscape-onprem` | Enroll Ubuntu into an on-premise Landscape service |
| `rtd-burniso` | Write an ISO to optical media |
| `rtd-make-bootable-usb-drive` | Create bootable USB media |
| `rtd-make-bootable-cd` | Create bootable ISO/CD media |
| `rtd-clear_iptables` | Clear/reset iptables configuration |
| `rtd-start-routes` | Configure forwarding/routing rules |
| `rtd-netuse` | Mount SMB/Windows network shares |
| `rtd-ssh-connection-list-local` | Find local-network SSH endpoints and connect |
| `rtd-internet-location` | Query public IP/location information |
| `rtd-malware-scan`, `rtd-malware-scan-HOME` | Run ClamAV scans |
| `rtd-deb-cleanup` | Clean Debian-family package/system artifacts |
| `rtd-oem-old-kernel-remover` | Remove old installed kernels |
| `rtd-ppa-checker` | Inspect or clean PPA repository state |
| `rtd-clear-zombie` | Assist with zombie-process cleanup |
| `rtd-restart-sound` | Restart/reload sound services |
| `rtd-tracker-force-update` | Force a Tracker index update |
| `rtd-xterm-sysconsole` | Open an interactive system console monitor |
| `rtd-configure-huion` | Configure a Huion tablet |
| `rtd-dropbox-on-ecryptfs` | Configure Dropbox use with encrypted home storage |
| `rtd-get-Windows-product-key` | Retrieve a firmware-stored Windows product key |
| `rtd-organize-everything` | Organize files by extension |
| `rtd-mv` | Move selected file types from a tree to a destination |
| `rtd-unrar-all` | Extract RAR archives recursively |
| `rtd-join-avi` | Combine AVI media files |
| `rtd-make-swap` | Create/configure swap storage |
| `rtd-on-notify-wait` | Wait for an operation or file and send notification |

Several administration helpers are inherently disruptive, especially media writing, routing/firewall, package cleanup, kernel removal, and file movement. Read the command header or invoke help where available before running them on important systems.
