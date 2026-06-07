# RTD Modules

[Back to RTD Power Tools](../README.md) | [Tool Reference](../docs/TOOLS.md) | [Use Cases](../docs/USE_CASES.md)

Modules contain the commands installed by RTD Power Tools. During installation, executable files beginning with the configured prefix, normally `rtd-`, are registered so they can be run from the shell.

## User-Facing Modules

| Task area | Module documentation | Main commands |
| --- | --- | --- |
| Maintenance | [System Update](oem-system-update.mod/README.md) | `rtd-update-system`, `rtd-self-update` |
| Software setup | [Bundle Manager](oem-bundle-manager.mod/README.md) | `rtd-oem-bundle-manager` |
| Games | [Lightweight Office Games](light-weight-office-games.mod/README.md) | `rtd-light-weight-office-games` |
| Backup | [User Backup](system-user-backup.mod/README.md) | `rtd-oem-backup-linux-config` |
| Remote support | [Simple Support Tool](simple-support-tool.mod/README.md) | `rtd-simple-support-tool` |
| Hardware reporting | [System Hardware Information](system-hardware-information.mod/README.md) | `rtd-system-hardware-information` |
| Desktop configuration | [Theme Manager](theme-manager/README.md), [Desktop Look Switcher](rtd-desktop-look-switcher.mod/README.md), [OEM Tweaks](rtd-oem-tweaks.mod/README.md) | `rtd-theme-manager`, `rtd-desktop-look-switcher`, `rtd-oem-tweaks` |
| Boot media | [Ventoy USB Creator](oem-ventoy.mod/README.md) | `rtd-ventoy-usb` |
| Virtualization | [VM Tool](vm-tool.mod/README.md), [macOS KVM](macos-kvm.mod/README.md), [Whonix](setup-whonix.mod/README.md) | `rtd-vm-tool`, `rtd-macos-kvm`, `rtd-setup-whonix.sh` |
| Networking | [VPN Router](rtd-vpn-router.mod/README.md), [NordVPN Manager](nordvpn-manager.mod/README.md) | `rtd-start-vpn-router`, `rtd-nordvpn` |
| Security | [Security Tool](Security-tool.mod/README.md), [Checksec](rtd-check-sec.mod/README.md) | `rtd-security-tool`, `rtd-check-sec` |
| Specialist utilities | [Minecraft](minecraft-server-manager.mod/README.md), [AI Chat](rtd-ai-chat.mod/README.md), [OEM App Runner](oem-app-runner.mod/README.md) | `rtd-minecraft-server`, `rtd-ai-chat`, `rtd-oem-app-runner` |
| Administration helpers | [System Admin Tools](oem-system-admin.mod/README.md) | `rtd-script-menu` and individual helper commands |

The complete installed-command catalog is maintained in [Tool Reference](../docs/TOOLS.md), including the system-admin helper commands that are intentionally not promoted individually on the landing page.

## Module Layout

A contributed module normally has this shape:

```text
modules/
  name.mod/
    rtd-name-of-script
    README.md
```

Each public command README should document its purpose, appropriate use cases, exact invocation, requirements, system changes, safety considerations, and related commands. Shared functions belong in [`core/_rtd_library`](../core/README.md).
