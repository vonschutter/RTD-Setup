# RTD Core Library

[Back to RTD Power Tools](../README.md) | [Module Index](../modules/README.md) | [Repository Index](../docs/REPOSITORY_INDEX.md)

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
| `rtd-vm-template-finalize-linux.sh` | Default bundle installation and validated VM template reseal |
| `rtd-oem-macos-config.sh` | macOS configuration entry point |
| `rtd-oem-windows-setup.ps1` | Unified, capability-driven Windows 10+ configuration worker |
| `rtd-oem-windows-setup-splash.ps1` | Interactive Windows WPF setup frontend |

## What `_rtd_library` Provides

Linux modules source `_rtd_library` to reuse package-management, UI, logging, system, desktop, network, security, media, and virtualization routines. This prevents individual tools from reimplementing distro detection, dependency installation, dialog handling, and standard logging.

Native package requests use `software::add_native_package` as a best-effort
operation. It checks repository availability, warns about skipped or failed
requests, and continues with the remaining packages. Its success status does
not guarantee installation. Invalid arguments, privilege failures, and unsupported
package managers still return errors.

Use `software::check_native_package_dependency` for required packages. It checks
availability and verifies the installed state after attempting installation,
returning nonzero if any dependency cannot be satisfied. Propagate that failure
before running code that needs the dependency:

```bash
software::add_native_package rar 7zip-rar
software::check_native_package_dependency curl git || return 1
```

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

Modern Ubuntu VDI builds request an installer reboot and let `virt-install`
start the installed disk once installation completes. Installation media is
removed from the persistent VM definition while remaining available to the live
installer. OEM autologin and the existing sudo authorization start the stage-two
finalizer, which installs default bundles, prepares first-user setup, and powers
off only after reseal succeeds. A failed bundle install or reseal leaves the VM
running for diagnosis and retains the stage-two marker.

Ubuntu GNOME builds use GDM's native first-user setup. Kubuntu and other Ubuntu
desktops without GDM use Ubuntu's packaged graphical `oem-config-gtk` wizard,
selected through the native OEM service. Stage two also installs Xorg, which
the OEM wizard requires even when Plasma normally runs on Wayland. The delivery
boot opens the graphical wizard before returning to the existing desktop display
manager; the wizard does not run during automated template finalization.

Debian GNOME desktop templates use the same native GDM first-user handoff.
Preseed creates the temporary build/recovery account at UID 29998, leaving UID
1000 free for the deployed user. After the installer reboot, the existing RTD
finalizer installs default bundles, hides the recovery account from
AccountsService, enables GNOME Initial Setup, and shuts down after reseal.
Other Debian desktops retain manual finalization. Existing images whose build
account occupies UID 1000 must be rebuilt or have that account migrated while
logged out before resealing; RTD refuses to reseal them as ready for first-user
setup.

Debian VM definitions include both SPICE and QEMU guest-agent channels, and
installation explicitly includes the SSH server and guest agents. RTD attaches
the SPICE user service to `graphical-session.target`, including Debian's static
unit without an `[Install]` section. The legacy desktop launcher stays disabled
so only one session agent runs. A running daemon alone is insufficient for
clipboard and display integration; the graphical session needs its user agent.

Debian's `virt-install` watcher runs under `nohup` with detached stdin and an
explicit unlimited install wait, so closing the build launcher does not interrupt
the one-time restart from installer to installed disk. Final OEM shutdown remains
a power-off. Unattended update checks (`RTD_NONINTERACTIVE=1` or
`DEBIAN_FRONTEND=noninteractive`) log and defer required reboots to the calling
workflow; interactive update commands retain their reboot confirmation.
