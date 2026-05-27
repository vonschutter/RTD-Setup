# RTD Power Tools Use Cases

[Back to README](../README.md) | [Getting Started](GETTING_STARTED.md) | [Tool Reference](TOOLS.md)

These examples describe tasks RTD tools are intended to simplify. Review the referenced module documentation before running commands that write disks, modify networking, or make system configuration changes.

## Configure A Fresh Linux Workstation

Use this after installing a desktop distribution or rebuilding a personal workstation.

```bash
rtd-oem-bundle-manager
rtd-oem-tweaks
rtd-update-system
```

| Tool | Use in this workflow |
| --- | --- |
| `rtd-oem-bundle-manager` | Select application or configuration bundles by task rather than installing each package manually |
| `rtd-oem-tweaks` | Apply optional GNOME desktop usability defaults |
| `rtd-desktop-look-switcher` | Optionally apply a familiar GNOME visual preset |
| `rtd-update-system` | Bring native packages, Flatpaks, and snaps up to date |

Expect software downloads and desktop setting changes. Run the desktop tools as the desktop user so settings are applied to the intended account.

## Support A Linux Computer Remotely

Use this when investigating or maintaining a machine through SSH or a local terminal.

```bash
rtd-simple-support-tool
rtd-update-system --show
```

`rtd-simple-support-tool` groups common support functions such as system reporting, update tasks, and maintenance operations. `rtd-update-system --show` is a read-only way to check what package activity occurred today before deciding whether further changes are required.

For a local graphical session, add:

```bash
rtd-system-hardware-information
```

## Back Up And Reinstall A User Computer

Use this before changing a distribution, replacing a drive, or rebuilding a workstation.

```bash
rtd-oem-backup-linux-config
rtd-ventoy-usb
```

1. Use `rtd-oem-backup-linux-config` to create encrypted archives of the required user data and configuration.
2. Confirm the backup archive can be found on the external or mounted destination.
3. Use `rtd-ventoy-usb` to prepare installation media only after confirming the correct removable drive.
4. After installation, restore required user files and run `rtd-oem-bundle-manager` to re-add selected application bundles.

`rtd-ventoy-usb` erases its selected device. It must not be pointed at the disk holding the only copy of a backup.

## Maintain The RTD Installation

Use this when the tools themselves need to be refreshed from the repository.

```bash
rtd-update-self
```

The normal update path stages a new checkout, backs up the current `/opt/rtd` contents, then synchronizes the staged repository into place while retaining unmatched local files. Choose refresh/reinitialize only when a clean replacement is required because local files are stale or inconsistent.

## Build A Virtual Test Lab

Use this for operating-system testing, reusable server or desktop guests, and specialized guest environments.

```bash
rtd-vm-tool
```

Related specialized commands:

```bash
rtd-macos-kvm doctor
sudo rtd-macos-kvm prepare --version sonoma
sudo rtd-setup-whonix.sh
```

| Tool | Appropriate purpose |
| --- | --- |
| `rtd-vm-tool` | Common KVM/libvirt desktop and server guest workflows |
| `rtd-macos-kvm` | Preparing supported macOS recovery installation assets and defining a guest |
| `rtd-setup-whonix.sh` | Deploying Whonix Gateway and Workstation guests |

These tools require a KVM-capable host and may install packages or create large VM images. For macOS guests, comply with applicable Apple licensing requirements.

## Create A VPN Gateway

Use this when a dedicated Linux host or VM should forward LAN traffic through a VPN client.

```bash
sudo rtd-start-vpn-router
```

The tool configures routing and firewall rules and can assist with supported VPN clients. Set a stable address for the gateway host before directing client devices to it. Perform this workflow from a connection path that will not be lost if routing changes require correction.

For simple interactive NordVPN use on one computer, use:

```bash
rtd-nordvpn
```

## Inspect Or Harden A Linux Host

Use the menu-driven security tool for configuration actions:

```bash
rtd-security-tool
```

Use `rtd-check-sec` for read-only inspection of executable or kernel hardening indicators:

```bash
rtd-check-sec --file /usr/bin/ssh
rtd-check-sec --kernel
```

Security tool actions can change firewall, audit, malware-scanning, or system-hardening settings. `rtd-check-sec` is suited to checking mitigation status before making configuration decisions.
