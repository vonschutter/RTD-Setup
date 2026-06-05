# Getting Started With RTD Power Tools

[Back to README](../README.md) | [Use Cases](USE_CASES.md) | [Tool Reference](TOOLS.md)

RTD Power Tools installs interactive `rtd-*` commands that assist with common Linux administration, desktop setup, support, media creation, networking, and virtualization tasks.

## Installation

On Linux, download and run the bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/rtd-me.sh.cmd -o rtd-me.sh.cmd
bash ./rtd-me.sh.cmd
```

The installer may request administrator privileges. Installed Linux tools and their module files are normally placed under `/opt/rtd`.

## Discover Commands

After installation, use shell completion to see available commands:

```bash
rtd<TAB><TAB>
```

Use the [Tool Reference](TOOLS.md) when you know a command name, or [Use Cases](USE_CASES.md) when you know the job but not the command.

## Good First Commands

| Goal | Command |
| --- | --- |
| Install selected application bundles on a new workstation | `rtd-oem-bundle-manager` |
| Apply optional GNOME desktop defaults | `rtd-oem-tweaks` |
| Update installed applications and packages | `rtd-update-system` |
| Review updates installed today without changing the system | `rtd-update-system --show` |
| Display hardware information | `rtd-system-hardware-information` |

## User Interface And Remote Sessions

Some tools use graphical interfaces such as Zenity or YAD and are intended for a logged-in desktop session. Other tools use terminal/dialog interfaces and are suitable for SSH support work. The tool reference identifies the expected interface where it matters.

For remote support, a useful starting point is:

```bash
rtd-simple-support-tool
```

## Administrator Privileges

Read-only reporting operations may run without elevation. Tools that install packages, manage `/opt/rtd`, configure networking or security, write removable drives, or define system virtual machines require `sudo`, `pkexec`, or an equivalent authorization prompt.

Before executing an unfamiliar tool, review its module README and built-in `--help` output when provided.

## Updates And Logs

Update software installed on the system:

```bash
rtd-update-system
```

Review package activity for the current day:

```bash
rtd-update-system --show
```

Update the RTD toolset itself:

```bash
rtd-self-update
```

`rtd-self-update` stages new repository content, backs up `/opt/rtd` under `/opt/backup`, and synchronizes updates into the installation. Its refresh/reinitialize option performs a clean replacement when local or orphaned files must be discarded.

System-level RTD logs are generally written under `/var/log/rtd`. User-level operations may use `~/.config/rtd/log`.

## Operations Requiring Care

| Operation | Tool | Why to review it carefully |
| --- | --- | --- |
| USB creation | `rtd-ventoy-usb` | Erases and formats the selected target drive |
| VPN gateway setup | `rtd-start-vpn-router` | Changes routing/firewall behavior; monitors an active service on no-argument launch |
| Security configuration | `rtd-security-tool` | May alter firewall, audit, password, or intrusion-detection configuration |
| User backup | `rtd-oem-backup-linux-config` | Creates encrypted archives; passphrase and destination are essential |
| Virtual machines | `rtd-vm-tool`, `rtd-macos-kvm`, `rtd-setup-whonix.sh` | Installs virtualization dependencies and creates disk images/domains |

## Developers And Module Authors

If you are adding commands or working directly with shared functions, read the [Core Library documentation](../core/README.md) and [Module Index](../modules/README.md).
