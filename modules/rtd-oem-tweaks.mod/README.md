# RTD OEM Tweaks

`rtd-oem-tweaks` is a GTK checklist tool for GNOME desktops.

It exposes useful GNOME tweak functions from `core/_rtd_library`, including:

- Core/common UI bundles (`gnome::set_ui_tweaks_for_user`, `gnome::set_ui_common_tweaks_for_user`)
- Usability and desktop tuning (`set_better_usability_for_user`, `configure_nautilus`, `organize_overlay_menu`, `set_power_configuraton_for_user`, `set_better_font_smoothing_for_user`)
- Extension and panel/dock tuning (`set_basic_extensions_enabled`, `configure_dash_to_dock`, `configure_dash_to_panel`)
- Terminal and Tilix preferences (`set_tilix_ui_tweaks_for_user`, `_apply_terminal_preferences`)
- Theme maintenance helpers (`_reset_ui_theme_settings`, `_reload_shell_theme`, `ensure_window_buttons_visible`, `_apply_gtk4_theme`)
- Startup sound control (`set_startup_sound`)
- Full style presets (Windows 10, macOS, Corporate Crisp, Moca)

## Usage

Run:

```bash
rtd-oem-tweaks
```

## Notes

- Must be run as the regular desktop user (not `root`) so `gsettings` updates the correct GNOME profile.
- Requires a GNOME desktop session.
- Uses `zenity` for the GTK checklist UI.
- Some advanced items prompt for extra input (for example custom GTK4 theme values or startup sound file).
