# RTD Ventoy USB Creator 💾🧭

![Ventoy Flow](Media_files/ScrRTDTerm.png?raw=true)

Interactive helper that wraps the Ventoy functions in `core/_rtd_library` to build a branded, multi-ISO USB stick in just a few steps.

## What It Does
- 🚀 Downloads the latest (or requested) Ventoy release to a cache directory.
- 🔌 Prompts for the target removable USB drive (or honor `--device`).
- 🧹 Installs Ventoy (destructive), formats the data partition as ext4.
- 📁 Builds RTD folder layout and copies discovered ISOs grouped by type.
- 🎨 Applies RTD theme/branding to the Ventoy menu.

## Quickstart
```bash
rtd-ventoy-usb
# or specify the device and allow overwrites
rtd-ventoy-usb --device /dev/sdb --overwrite
```

## Options
- `--device /dev/sdX` : Explicit target block device.
- `--version 1.0.99`  : Pin a Ventoy version (default: latest).
- `--dest /path`      : Cache/extract Ventoy into a custom directory.
- `--overwrite`       : Replace ISOs that already exist on the stick.
- `-h, --help`        : Show help.
- `-V, --script-version` : Print wrapper version.

## Dialog-Driven UX
- Uses `dialog` for notices and confirmation before running the destructive step.
- Falls back to simple terminal prompts if `dialog` is unavailable.

## Safety
- ⚠️ **ALL DATA ON THE SELECTED DEVICE WILL BE ERASED.**
- Requires tools such as `dialog`, `curl`/`wget`, `tar`, `gzip`; these are checked/installed via the shared RTD library loader.

## File Map
- `rtd-ventoy-usb` — entry point; sources `core/_rtd_library` and calls `oem::ventoy::setup_usb`.
