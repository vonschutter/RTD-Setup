# VM Tool Module

![RTD VM Tool](Media_files/header-time.jpg)

This module ships `rtd-vm-tool`, a menu-driven Bash utility for managing KVM/libvirt virtual machines in the RTD stack, and `rtd-vm-tool-gtk`, a Zenity-based GTK front-end that mirrors the same menu tree. Both tools **require** the shared `_rtd_library` (auto-fetched if not already loaded). The tools call `rtd::bootstrap_library "_rtd_library"` on startup and exit if the library cannot be sourced.

## Features

- Dialog (Text GUI) based interface for common VM operations.
- Zenity/GTK launcher for the same main/template/settings/maintenance menu tree.
- Server VM deploy: clone server templates with optional post-clone Ansible pull (via `vmtool::post_clone_ansible_pull`).
- Virtual desktop deploy: clone VDI templates.
- Create VM templates: guided creation for server roles (Ubuntu, Debian, Fedora, etc.) and VDI desktops.
- Start/stop VMs from a simple menu.
- Settings: adjust clone preferences via `RTD_VM_CLONE_ARGS`.
- Maintenance: run cleanup helpers and toggle GNOME Boxes integration from a dedicated menu.
- macOS KVM workflow: prepare macOS recovery/installer media, define a QEMU/KVM domain, and continue through the Apple installer and first-boot setup.

## Requirements

- Bash shell.
- KVM/libvirt on the host with appropriate permissions; `virsh`/`qemu` available.
- `dialog` for the TUI (`RTD_GUI` controls the picker; default `dialog`).
- `_rtd_library` v2.04+ (loaded via `rtd::bootstrap_library "_rtd_library"` inside the script). The tool depends on `kvm::` functions and `write_*` helpers and will not operate without the library.

## Usage

```bash
bash rtd-vm-tool
```

GTK front-end:

```bash
bash rtd-vm-tool-gtk
```

Clone options accepted by the terminal tool are also accepted by the GTK front-end and passed through to clone workflows:

```bash
bash rtd-vm-tool-gtk --sysprep
bash rtd-vm-tool-gtk --customize "--install htop"
```

If installed on your `$PATH`, simply run:

```bash
rtd-vm-tool
```

## Screenshots

### Terminal Interface

![rtd-vm-tool terminal interface](Media_files/Screenshot_rtd-vm-tool.png)

### GTK Interface

![rtd-vm-tool GTK interface](Media_files/Screenshot_rtd-vm-tool-gtk.png)

### Ubuntu VDI

![Ubuntu VDI running through RTD VM Tool](Media_files/Screenshot_Ubuntu_VDI.png)

### Fedora VDI

![Fedora VDI running through RTD VM Tool](Media_files/Screenshot_Fedora_VDI.png)

### Fedora KDE VDI

![Fedora KDE VDI running through RTD VM Tool](Media_files/Screenshot_Fedora_VDI_KDE.png)

### Windows 11 VDI

![Windows 11 VDI running through RTD VM Tool](Media_files/Screenshot_Windows11_VDI.png)

## Notes

- Logging/output follows the script’s dialog/whiptail presentation and `write_*` helpers from `_rtd_library`.
- The tool honors RTD branding/version strings defined at the top of the script.
- `_rtd_library` is plain Bash and publicly auditable in the RTD-Setup repository.
- The GNOME Boxes integration maintenance task toggles the `QEMU System` libvirt source file when an existing GNOME Boxes config directory is found:
  - `~/.config/gnome-boxes/sources/QEMU System`
  - `~/.var/app/org.gnome.Boxes/config/gnome-boxes/sources/QEMU System`
- For Flatpak GNOME Boxes, adding integration grants access to `/run/libvirt` with `flatpak override --user --filesystem=/run/libvirt org.gnome.Boxes` and writes the source URI with an explicit libvirt socket path. Removing integration deletes the source file and revokes that override.
