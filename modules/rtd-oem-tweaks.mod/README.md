# RTD OEM Tweaks

`rtd-oem-tweaks` is a GTK checklist tool for GNOME desktops. It presents
individual GNOME tweaks as selectable actions and can save reusable tweak
profiles under `~/.config/rtd/oem-tweak-profiles/`.

It exposes useful GNOME tweak functions from `core/_rtd_library`, including:

- Individual usability and desktop settings such as mouse acceleration, window
  buttons, workspace behavior, clock details, battery percentage, hot corners,
  sleep behavior, and Tracker battery behavior.
- Nautilus and app-grid tuning (`configure_nautilus`, `organize_overlay_menu`)
- Extension and panel/dock tuning (`set_basic_extensions_enabled`, `configure_dash_to_dock`, `configure_dash_to_panel`)
- Terminal and Tilix preferences (`set_tilix_ui_tweaks_for_user`, `_apply_terminal_preferences`)
- Theme maintenance helpers (`_reset_ui_theme_settings`, `_reload_shell_theme`, `ensure_window_buttons_visible`, `_apply_gtk4_theme`)
- Startup sound control (`set_startup_sound`)

Full visual style presets such as Windows, macOS, Corporate Crisp, and Moca are
intentionally handled by the separate theme tooling, not this tweak tool.

## Usage

Run:

```bash
rtd-oem-tweaks
```

Print live tweak status:

```bash
rtd-oem-tweaks --status
```

## Profiles

Use the `SAVE PROFILE`, `LOAD PROFILE`, and `DELETE PROFILE` buttons in the
main window. Profiles are simple text files stored in:

```text
~/.config/rtd/oem-tweak-profiles/
```

Each profile contains one tweak ID per line, making it easy to inspect or copy
profiles between systems.

## Notes

- Must be run as the regular desktop user (not `root`) so `gsettings` updates the correct GNOME profile.
- Requires a GNOME desktop session.
- Uses `zenity` for the GTK checklist UI.
- Some advanced items prompt for extra input (for example custom GTK4 theme values or startup sound file).
