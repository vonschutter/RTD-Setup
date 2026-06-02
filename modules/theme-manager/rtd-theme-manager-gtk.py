#!/usr/bin/env python3
"""GTK frontend for the RTD GNOME Theme Manager."""

import ast
import os
from pathlib import Path
import subprocess
import sys

try:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import GdkPixbuf, Gtk
except (ImportError, ValueError) as error:
    raise SystemExit(
        "RTD Theme Manager requires GTK 3 Python bindings (python3-gi): "
        f"{error}"
    )


APP_DIR = Path(__file__).resolve().parent
BACKEND = APP_DIR / "rtd-theme-manager"
BANNER = APP_DIR / "Media_files" / "theme-manager-banner.png"
KEEP = "__KEEP__"
THEME_ROOTS = (Path.home() / ".themes", Path("/usr/share/themes"))
ICON_ROOTS = (Path.home() / ".icons", Path.home() / ".local/share/icons", Path("/usr/share/icons"))
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def directories(roots, marker=None):
    names = set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.iterdir():
            if path.is_dir() and (marker is None or (path / marker).exists()):
                names.add(path.name)
    return sorted(names, key=str.casefold)


def theme_names(marker):
    return directories(THEME_ROOTS, marker)


def theme_path(name):
    for root in THEME_ROOTS:
        path = root / name
        if path.is_dir():
            return path
    return None


def wallpapers(name):
    root = theme_path(name)
    if root is None:
        return []
    return sorted(
        (
            path
            for path in root.rglob("*")
            if path.is_file()
            and path.suffix.lower() in IMAGE_SUFFIXES
            and len(path.relative_to(root).parts) <= 3
        ),
        key=lambda path: str(path).casefold(),
    )


def get_setting(schema, key, fallback=""):
    try:
        result = subprocess.run(
            ["gsettings", "get", schema, key],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        ).stdout.strip()
        value = ast.literal_eval(result)
        return value if isinstance(value, str) else fallback
    except (FileNotFoundError, subprocess.CalledProcessError, SyntaxError, ValueError):
        return fallback


def combo(values, current=""):
    widget = Gtk.ComboBoxText()
    for value in values:
        widget.append_text(value)
    if current in values:
        widget.set_active(values.index(current))
    elif values:
        widget.set_active(0)
    return widget


def combo_value(widget, fallback=KEEP):
    return widget.get_active_text() or fallback


class ThemeManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="RTD GNOME Theme Manager")
        self.set_default_size(920, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(0)
        self.connect("destroy", Gtk.main_quit)

        self.gtk_themes = sorted(
            set(theme_names("gtk-3.0") + theme_names("gtk-4.0")),
            key=str.casefold,
        )
        self.shell_themes = theme_names("gnome-shell")
        self.icon_themes = directories(ICON_ROOTS, "index.theme")
        self.cursor_themes = directories(ICON_ROOTS, "cursors")
        self.complete_themes = sorted(
            set(self.gtk_themes + self.shell_themes + self.icon_themes + self.cursor_themes),
            key=str.casefold,
        )

        self.current_gtk = get_setting("org.gnome.desktop.interface", "gtk-theme")
        self.current_shell = get_setting("org.gnome.shell.extensions.user-theme", "name")
        self.current_icons = get_setting("org.gnome.desktop.interface", "icon-theme")
        self.current_cursor = get_setting("org.gnome.desktop.interface", "cursor-theme")
        self.current_color = get_setting("org.gnome.desktop.interface", "color-scheme", "default")

        self.add(self.build_window())
        self.show_all()
        self.global_wallpaper_box.set_sensitive(self.global_wallpaper_switch.get_active())
        self.custom_wallpaper.set_sensitive(self.custom_wallpaper_switch.get_active())

    def build_window(self):
        layout = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        layout.pack_start(self.build_banner(), False, False, 0)

        notebook = Gtk.Notebook()
        notebook.set_border_width(18)
        notebook.append_page(self.build_complete_page(), Gtk.Label(label="Complete Theme"))
        notebook.append_page(self.build_custom_page(), Gtk.Label(label="Individual Elements"))
        notebook.append_page(self.build_presets_page(), Gtk.Label(label="RTD Desktop Profiles"))
        layout.pack_start(notebook, True, True, 0)
        return layout

    def build_banner(self):
        overlay = Gtk.Overlay()
        if BANNER.is_file():
            pixels = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(BANNER), 920, 230, False)
            overlay.add(Gtk.Image.new_from_pixbuf(pixels))
        else:
            overlay.add(Gtk.Label(label=""))
        text = Gtk.Label()
        text.set_halign(Gtk.Align.START)
        text.set_valign(Gtk.Align.CENTER)
        text.set_margin_start(34)
        text.set_markup(
            "<span foreground='white' size='xx-large' weight='bold'>GNOME Theme Manager</span>\n"
            "<span foreground='#d7e8ff' size='large'>Shape your desktop, from one polished look to the smallest detail.</span>"
        )
        overlay.add_overlay(text)
        return overlay

    def page(self, title, description):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        heading = Gtk.Label()
        heading.set_halign(Gtk.Align.START)
        heading.set_markup(f"<span size='x-large' weight='bold'>{title}</span>")
        outer.pack_start(heading, False, False, 0)
        copy = Gtk.Label(label=description)
        copy.set_halign(Gtk.Align.START)
        copy.set_line_wrap(True)
        outer.pack_start(copy, False, False, 0)
        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        outer.pack_start(body, True, True, 0)
        return outer, body

    def row(self, grid, position, title, control):
        label = Gtk.Label(label=title)
        label.set_halign(Gtk.Align.START)
        grid.attach(label, 0, position, 1, 1)
        control.set_hexpand(True)
        grid.attach(control, 1, position, 1, 1)

    def build_complete_page(self):
        page, body = self.page(
            "Apply a coordinated theme",
            "Choose one installed theme. RTD applies every matching component it finds and leaves unavailable components unchanged.",
        )
        grid = Gtk.Grid(column_spacing=18, row_spacing=12)
        body.pack_start(grid, False, False, 4)
        self.global_theme = combo(self.complete_themes, self.current_gtk)
        self.global_theme.connect("changed", self.refresh_global_details)
        self.row(grid, 0, "Installed theme", self.global_theme)

        self.global_details = Gtk.Label()
        self.global_details.set_halign(Gtk.Align.START)
        self.global_details.set_line_wrap(True)
        grid.attach(self.global_details, 1, 1, 1, 1)

        self.global_wallpaper_switch = Gtk.Switch()
        self.global_wallpaper_switch.set_halign(Gtk.Align.START)
        self.global_wallpaper_switch.connect("notify::active", self.toggle_global_wallpapers)
        self.row(grid, 2, "Use included wallpaper", self.global_wallpaper_switch)
        self.global_wallpaper_box = combo([])
        self.row(grid, 3, "Wallpaper", self.global_wallpaper_box)

        apply_button = Gtk.Button(label="Apply Complete Theme")
        apply_button.get_style_context().add_class("suggested-action")
        apply_button.connect("clicked", self.apply_complete)
        body.pack_end(apply_button, False, False, 0)
        self.refresh_global_details()
        return page

    def build_custom_page(self):
        page, body = self.page(
            "Fine tune individual elements",
            "Mix and match the installed GNOME components. Current settings are preselected so you can change only what matters.",
        )
        grid = Gtk.Grid(column_spacing=18, row_spacing=12)
        body.pack_start(grid, False, False, 4)
        self.custom_gtk = combo(self.gtk_themes, self.current_gtk)
        self.custom_shell = combo(self.shell_themes, self.current_shell)
        self.custom_icons = combo(self.icon_themes, self.current_icons)
        self.custom_cursor = combo(self.cursor_themes, self.current_cursor)
        self.custom_color = combo(["default", "prefer-light", "prefer-dark"], self.current_color)
        self.custom_wallpaper_switch = Gtk.Switch()
        self.custom_wallpaper_switch.set_halign(Gtk.Align.START)
        self.custom_wallpaper_switch.connect("notify::active", self.toggle_custom_wallpaper)
        self.custom_wallpaper = Gtk.FileChooserButton(title="Choose a desktop wallpaper")
        image_filter = Gtk.FileFilter()
        image_filter.set_name("Images")
        image_filter.add_pixbuf_formats()
        self.custom_wallpaper.add_filter(image_filter)

        for position, (title, control) in enumerate(
            (
                ("Application theme", self.custom_gtk),
                ("GNOME Shell theme", self.custom_shell),
                ("Icon theme", self.custom_icons),
                ("Cursor theme", self.custom_cursor),
                ("Light or dark preference", self.custom_color),
                ("Change wallpaper", self.custom_wallpaper_switch),
                ("Wallpaper image", self.custom_wallpaper),
            )
        ):
            self.row(grid, position, title, control)

        note = Gtk.Label(
            label="Shell themes use the GNOME User Themes extension. RTD installs and enables it when needed, while still applying the other selections if GNOME requires a new login before activation."
        )
        note.set_halign(Gtk.Align.START)
        note.set_line_wrap(True)
        body.pack_start(note, False, False, 4)
        apply_button = Gtk.Button(label="Apply Selected Elements")
        apply_button.get_style_context().add_class("suggested-action")
        apply_button.connect("clicked", self.apply_custom)
        body.pack_end(apply_button, False, False, 0)
        return page

    def build_presets_page(self):
        page, body = self.page(
            "Explore RTD desktop profiles",
            "Open the familiar RTD Desktop Look Switcher for complete workstation profiles inspired by Windows, macOS, crisp professional layouts, and Moca Smooth.",
        )
        profiles = Gtk.Label(
            label="Available profiles\n\nWindows 10 Light and Dark  |  Mac OS Bright and Dusk\nCrisp Day and Evening  |  Moca Smooth  |  Distribution Reset"
        )
        profiles.set_halign(Gtk.Align.START)
        profiles.set_justify(Gtk.Justification.LEFT)
        body.pack_start(profiles, False, False, 12)
        launch = Gtk.Button(label="Open RTD Desktop Look Switcher")
        launch.connect("clicked", self.launch_presets)
        body.pack_end(launch, False, False, 0)
        return page

    def refresh_global_details(self, *_args):
        name = combo_value(self.global_theme, "")
        components = [
            label
            for label, choices in (
                ("Applications", self.gtk_themes),
                ("Shell", self.shell_themes),
                ("Icons", self.icon_themes),
                ("Cursors", self.cursor_themes),
            )
            if name in choices
        ]
        self.global_details.set_text(
            "Available components: " + (", ".join(components) if components else "No matching GNOME components found")
        )
        self.global_wallpaper_box.remove_all()
        for path in wallpapers(name):
            self.global_wallpaper_box.append_text(str(path))
        self.global_wallpaper_box.set_active(0)
        self.global_wallpaper_switch.set_sensitive(self.global_wallpaper_box.get_active_text() is not None)

    def toggle_global_wallpapers(self, *_args):
        self.global_wallpaper_box.set_sensitive(self.global_wallpaper_switch.get_active())

    def toggle_custom_wallpaper(self, *_args):
        self.custom_wallpaper.set_sensitive(self.custom_wallpaper_switch.get_active())

    def apply_complete(self, _button):
        name = combo_value(self.global_theme, "")
        if not name:
            self.message("No theme selected", "Install a GNOME theme and choose it from the list.", Gtk.MessageType.WARNING)
            return
        wallpaper = combo_value(self.global_wallpaper_box) if self.global_wallpaper_switch.get_active() else KEEP
        self.apply(
            name if name in self.gtk_themes else KEEP,
            name if name in self.shell_themes else KEEP,
            name if name in self.icon_themes else KEEP,
            name if name in self.cursor_themes else KEEP,
            KEEP,
            wallpaper,
        )

    def apply_custom(self, _button):
        wallpaper = self.custom_wallpaper.get_filename() if self.custom_wallpaper_switch.get_active() else KEEP
        if wallpaper is None:
            self.message("Choose a wallpaper", "Select an image or turn off the wallpaper option.", Gtk.MessageType.WARNING)
            return
        self.apply(
            combo_value(self.custom_gtk),
            combo_value(self.custom_shell),
            combo_value(self.custom_icons),
            combo_value(self.custom_cursor),
            combo_value(self.custom_color),
            wallpaper,
        )

    def apply(self, *values):
        result = subprocess.run(
            [str(BACKEND), "--apply", *values],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
        if result.returncode == 0:
            detail = result.stderr.strip() or "Your GNOME appearance settings have been updated."
            self.message("Theme applied", detail, Gtk.MessageType.INFO)
        else:
            self.message("Could not apply theme", result.stderr.strip() or "The theme update failed.", Gtk.MessageType.ERROR)

    def launch_presets(self, _button):
        try:
            subprocess.Popen([str(BACKEND), "--launch-presets"])
        except OSError as error:
            self.message("Could not open presets", str(error), Gtk.MessageType.ERROR)

    def message(self, title, detail, kind):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=Gtk.DialogFlags.MODAL,
            message_type=kind,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(detail)
        dialog.run()
        dialog.destroy()


if __name__ == "__main__":
    if os.environ.get("XDG_CURRENT_DESKTOP", "").lower().find("gnome") == -1:
        print("Warning: RTD Theme Manager is designed for GNOME desktops.", file=sys.stderr)
    ThemeManager()
    Gtk.main()
