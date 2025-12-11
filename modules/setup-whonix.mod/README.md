# Whonix KVM Installer Module

This module provides an idempotent installer for Whonix on KVM/libvirt, including automatic bundle discovery, download/verify, network setup, and VM definition. It is intended to be used within the RTD stack and depends on `_rtd_library` v2.05+ (2.04 is rejected).

Whonix is a security-focused, privacy-hardened operating system designed to route all traffic through Tor and reduce metadata leaks. Tor (The Onion Router) is a network that relays traffic through multiple volunteer-run nodes to obfuscate origin and destination, providing anonymity against network surveillance. Learn more at <https://www.whonix.org> and <https://www.torproject.org>.

## Features

- **Auto-discovery:** Fetches the latest Whonix GUI (LXQt) libvirt bundle and checksum from `https://download.whonix.org/libvirt/`.
- **Checksum verification:** Uses the published SHA-512 sums when available.
- **Idempotent extraction:** Reuses previously extracted XML/qcow2 when matching the current bundle.
- **Network handling:** Defines/starts Whonix networks if needed; keeps existing ones.
- **Image staging:** Moves qcow2/raw images into `/var/lib/libvirt/images` without overwriting unless `--refresh`.
- **VM definition:** Updates or defines Gateway/Workstation VMs, pointing XML to the correct qcow2 paths.
- **Version skip:** If installed Gateway/Workstation are already at or above the discovered version and no refresh/add is requested, the script exits early.
- **Extra workstation:** Optional creation of an additional workstation overlay.

## Usage

```bash
bash rtd-setup-whonix.sh [--refresh] [--add]
```

### To simply setup Whonix on your computer automatically run

```bash
bash rtd-setup-whonix.sh 
```

### Alternatively, run it directly from the git repo without cloning

```bash
bash <(curl -sL https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/modules/setup-whonix.mod/rtd-setup-whonix.sh)
```

## Contents

- `rtd-setup-whonix.sh` – entrypoint script using RTD library helpers and `whonix::` functions defined in `_rtd_library`.

## Prerequisites

- Bash with RTD library available and `RTD_VERSION` > 2.04 (enforced by the script).
- sudo/admin privileges (handled via `security::ensure_admin`).
- KVM/libvirt capable host.

The script will:

- Install required packages using `software::check_native_package_dependency` (qemu, libvirt, virt-manager, dnsmasq, qemu-utils, iptables, xz-utils, wget, gir1.2-spiceclientgtk-3.0).
- Ensure the user is in `libvirt` and `kvm` groups (no-op if already present).
- Ensure the default libvirt network exists and is autostarted.

Flags:

- `--refresh` – Force re-define VMs and replace staged images with the newly downloaded bundle (networks are kept).
- `--add` – When the existing workstation is already on the current version, create one additional workstation VM (Gateway untouched).

Typical flow:

1. Load `_rtd_library` (local copies preferred; falls back to cloning/downloading the RTD repo).
2. Enforce RTD version > 2.04.
3. Elevate privileges (for package installs, group membership, libvirt operations).
4. Discover latest bundle; optionally skip if current VMs are already up to date.
5. Download + verify, extract, ensure networks, stage images, define VMs, report success.

## Paths and state

- Work dir: `${HOME}/.local/share/whonix-kvm`
- Images: `/var/lib/libvirt/images`
- Uses a marker `.bundle.name` in the work dir to avoid unnecessary re-extracts.

## Notes

- Logging/output uses RTD `write_*` helpers and will also log via the library.
- If `_rtd_library` cannot be loaded or the version check fails, the script aborts.
- Bundle preference is the GUI/LXQt variant; falls back to any libvirt bundle if LXQt is unavailable.
