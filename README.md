# RTD Power Tools

![RTD Power Tools](media_files/header-time.jpg)

RTD Power Tools is a collection of interactive administration utilities for Linux workstations, remote support, installation media, networking, security checks, and KVM virtual machines. The commands are designed to turn multi-step system tasks into guided terminal or desktop workflows while keeping the underlying Bash scripts inspectable.

## Choose A Task

| I want to... | Command | What it does | Important note |
| --- | --- | --- | --- |
| Update installed software | `rtd-update-system` | Updates native packages, Flatpaks, and snaps when configured | May require a reboot |
| See updates installed today | `rtd-update-system --show` | Displays package activity for today | Read-only |
| Update RTD Power Tools | `rtd-self-update` | Backs up and synchronizes the installed RTD files | Changes `/opt/rtd` |
| Install software by role | `rtd-oem-bundle-manager` | Installs selected application/configuration bundles | Downloads and installs software |
| Back up a user before a reinstall | `rtd-oem-backup-linux-config` | Builds encrypted archives of selected user data | Provide external or mounted storage |
| Diagnose or maintain a remote system | `rtd-simple-support-tool` | Presents common support tasks in one menu | Some tasks elevate privileges |
| View system hardware | `rtd-system-hardware-information` | Shows hardware and sensor information in a dashboard | Desktop UI required |
| Build a multi-ISO boot USB | `rtd-ventoy-usb` | Installs Ventoy and copies installation media | Erases the selected drive |
| Build or manage KVM guests | `rtd-vm-tool` | Creates, clones, starts, and maintains virtual machines | Requires KVM/libvirt |
| Route network traffic through a VPN | `rtd-start-vpn-router` | Configures a Linux host as a VPN gateway | Changes firewall and routing rules |

See the full [tool reference](docs/TOOLS.md) or start with the [example workflows](docs/USE_CASES.md).

## Install On Linux

Download and run the bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/rtd-me.sh.cmd -o rtd-me.sh.cmd
bash ./rtd-me.sh.cmd
```

The installer may request administrator privileges to install tools and dependencies under `/opt/rtd`. After installation, list available commands with shell completion:

```bash
rtd<TAB><TAB>
```

For first-run guidance, privilege expectations, and log locations, read [Getting Started](docs/GETTING_STARTED.md).

## Common Workflows

Set up and maintain a desktop workstation:

```bash
rtd-oem-bundle-manager
rtd-oem-tweaks
rtd-update-system
```

Back up a computer before reinstalling its operating system:

```bash
rtd-oem-backup-linux-config
rtd-ventoy-usb
```

Support a Linux computer over SSH:

```bash
rtd-simple-support-tool
rtd-update-system --show
```

More detailed examples, including virtual machines and VPN gateways, are in [Use Cases](docs/USE_CASES.md).

## Documentation

| Document | Intended reader |
| --- | --- |
| [Getting Started](docs/GETTING_STARTED.md) | Anyone installing or running RTD tools |
| [Use Cases](docs/USE_CASES.md) | Users choosing tools for a real task |
| [Tool Reference](docs/TOOLS.md) | Users looking up a specific `rtd-*` command |
| [Modules](modules/README.md) | Contributors and users browsing module packages |
| [Core Library](core/README.md) | Developers writing modules or using `_rtd_library` |

## Other Platforms

`rtd-me.sh.cmd` also contains Windows and macOS bootstrap paths. On Windows, configuration is performed through the PowerShell configuration scripts in `core/`; on macOS, the bootstrap invokes the macOS configuration script. Most `rtd-*` module commands documented here are Linux tools.

## Safety

Several RTD tools intentionally make system-level changes. In particular, review the prompts before using disk-writing, network-routing, security-hardening, backup, virtual-machine, or operating-system configuration commands. Module documentation identifies the expected effects and requirements for these workflows.

Contributions and corrections are welcome; see the repository license for terms.
