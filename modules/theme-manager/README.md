# RTD GNOME Theme Manager

[Back to Tool Reference](../../docs/TOOLS.md) | [Back to Modules](../README.md)

## Purpose

`rtd-theme-manager` discovers available GNOME themes and provides a graphical selector for applying GTK, Shell, icon, cursor, and optional wallpaper settings for the current user.

## Good For

- Switching between themes already installed on a GNOME desktop.
- Applying a theme's included wallpaper through one dialog.
- Completing theme setup without manually editing individual `gsettings` values.

## Requirements

- A GNOME desktop session.
- `gsettings`, `gnome-extensions`, and `zenity`.
- Themes installed under `~/.themes` or `/usr/share/themes`.

## Quick Start

Run this command as the logged-in desktop user:

```bash
rtd-theme-manager
```

Display built-in help:

```bash
rtd-theme-manager --help
```

## What It Changes

The tool updates desktop theme and optional wallpaper settings for the current GNOME user. It may use the RTD GNOME Shell extension installer when a selected theme requires extension support.

## Related Tools

- [`rtd-desktop-look-switcher`](../rtd-desktop-look-switcher.mod/README.md) applies complete RTD visual presets.
- [`rtd-oem-tweaks`](../rtd-oem-tweaks.mod/README.md) applies selected workstation usability settings.
- [`rtd-gnome-shell-extension-installer`](../gnome-shell-extension-installer.mod/README.md) installs extensions directly.
