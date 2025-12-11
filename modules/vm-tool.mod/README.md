# VM Tool Module

![RTD VM Tool](Media_files/header-time.jpg)

This module ships `rtd-vm-tool`, a menu-driven Bash utility for managing KVM/libvirt virtual machines in the RTD stack. It helps with routine VM tasks from a single TUI, using the shared `_rtd_library` helpers when available.

## Features
- Dialog/whiptail-based interface for common VM operations.
- Works with KVM/libvirt environments; checks for needed dependencies.
- Designed to be portable: can run standalone or alongside RTD tooling.

## Requirements
- Bash shell.
- KVM/libvirt on the host with appropriate permissions.
- (Optional) `_rtd_library` for enhanced helpers; the script runs standalone if needed.

## Usage
```bash
bash rtd-vm-tool
```
If installed on your `$PATH`, simply run:
```bash
rtd-vm-tool
```

## Screenshot

![VM Tool Menu](Media_files/Screenshot.png)

## Notes
- Logging/output follows the script’s built-in dialog/whiptail presentation.
- The tool honors RTD branding/version strings defined at the top of the script.
