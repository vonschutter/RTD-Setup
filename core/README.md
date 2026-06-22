# RTD Core Library

[Back to RTD Power Tools](../README.md) | [Module Index](../modules/README.md)

This document is for module authors and maintainers. Users looking for commands to accomplish a system task should start with the [tool reference](../docs/TOOLS.md) or [use cases](../docs/USE_CASES.md).

## Contents

| Path | Purpose |
| --- | --- |
| `_rtd_library` | Shared Linux Bash functions used by module scripts |
| `_rtd_recipies.info` | Software bundles and installation recipes |
| `_branding.info` and location configuration | RTD names, paths, URLs, and presentation defaults |
| `sigs/` | Hashes used when verifying packaged OEM applications |
| `rtd-oem-enable-config.sh` | Registration/configuration path used during automated installs |
| `rtd-oem-linux-config.sh` | Linux workstation, server, or VM configuration entry point |
| `rtd-oem-macos-config.sh` | macOS configuration entry point |
| `rtd-oem-win10-config.ps1`, `rtd-oem-win11-config.ps1` | Windows configuration workers |
| `windows-setup-splash.ps1` | Interactive Windows 11 WPF setup frontend |

## What `_rtd_library` Provides

Linux modules source `_rtd_library` to reuse package-management, UI, logging, system, desktop, network, security, media, and virtualization routines. This prevents individual tools from reimplementing distro detection, dependency installation, dialog handling, and standard logging.

Major function namespaces include:

| Namespace | Responsibility |
| --- | --- |
| `dialog::`, `yad::`, `zenity::`, `term::` | Interactive UI and terminal output |
| `system::` | System information, services, logging, and files |
| `software::` | Native packages, Flatpak, Snap, dependencies, and updates |
| `oem::`, `gnome::` | Installation branding and desktop configuration |
| `security::`, `disk::` | Security configuration, scans, and disk operations |
| `network::`, `ssh::` | Connectivity, transfer, and SSH helpers |
| `kvm::`, `whonix::` | Virtual-machine and specialized guest workflows |
| `template::`, `library::` | Configuration generation and library internals |
| `tool::` | General administration and media helpers |

## Loading The Library

`_rtd_library` is Linux-oriented and requires Bash 4.4 or newer. Apple ships
Bash 3.2 with macOS, which cannot parse several modern Bash features used by
the library.

On Linux with Bash 4.4 or newer, source it when a shell session needs to call
functions directly:

```bash
source core/_rtd_library
```

Module entry points typically bootstrap the library themselves and should validate the functions they require before continuing.

On macOS, use the dedicated configuration entry point instead of sourcing the
Linux library:

```bash
bash core/rtd-oem-macos-config.sh
```

Maintainers who need to inspect the Linux library on macOS can install modern
Bash through Homebrew and launch a compatible shell explicitly:

```bash
brew install bash
/opt/homebrew/bin/bash -c 'source core/_rtd_library'
```

On Intel Macs, Homebrew may install Bash under `/usr/local/bin/bash`.

## Built-In Help

Run the library directly to inspect the documented public function catalog:

```bash
bash core/_rtd_library --help
bash core/_rtd_library --list internal
bash core/_rtd_library --list internal kvm::
bash core/_rtd_library --devhelp
bash core/_rtd_library --devhelp-gtk
```

`--devhelp` is appropriate for terminal or SSH use. `--devhelp-gtk` presents the same developer-facing documentation through a graphical interface.

## Writing A Module

A public module command should:

1. Use an executable name beginning with the configured RTD prefix, normally `rtd-`.
2. Load `_rtd_library` through the established bootstrap pattern when shared helpers are required.
3. Keep user-facing entry-point logic in the module and reusable implementation in the appropriate library namespace.
4. Include concise header documentation for purpose, value, usage, examples, and requirements.
5. Include a module `README.md` documenting the task it solves, invocation, privileges, system changes, safety concerns, and related tools.
6. Add callable shared functions to the `_rtd_library` documentation catalog so they appear through `--devhelp`.

## Cross-Distribution Software Recipes

Package names can vary between distributions. Recipes may therefore use native packages, Flatpak, Snap, or vendor installers according to what the recipe supports. Module documentation should state when a command downloads software or configures an additional package channel.

## Automated Installation

RTD functions also support templates and configuration scripts used when building installation media or KVM guests through Preseed, Kickstart, AutoYaST, or Autounattend workflows. These are implementation facilities for tools such as `rtd-vm-tool`; they are not required reading for normal command use.
