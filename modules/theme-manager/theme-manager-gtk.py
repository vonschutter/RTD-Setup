#!/usr/bin/env python3

#
#::                          RTD GNOME Theme Manager GTK Frontend
#::                     G R A P H I C A L    F R O N T E N D
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#:: Module:     theme-manager
#:: Script:     theme-manager-gtk.py
#:: Author(s):  RTD Team (vonschutter)
#:: Version:    2.00
#::
#:: Purpose:    Provides the GTK window for the RTD GNOME Theme Manager. The
#::             frontend lets users apply complete GNOME theme sets, customize
#::             individual appearance elements, select RTD wallpapers, and launch
#::             integrated RTD desktop profiles through the rtd-theme-manager
#::             backend.
#::
#:: Usage:      rtd-theme-manager
#::
#:: Requires:   python3, python3-gi, GTK 3 introspection bindings, and the sibling
#::             rtd-theme-manager backend script.
#::
#:: Runtime:    This file is intentionally not named rtd-* and is not intended to
#::             be installed as a direct command. Use rtd-theme-manager so RTD can
#::             validate the desktop environment, route KDE users to the native
#::             KDE Global Theme module, and install Python GTK dependencies before
#::             this frontend is executed.
#::
#:: Notes:      GNOME Shell theme changes depend on the User Themes extension and
#::             may require logout/login before every change is visible. Wallpaper
#::             selection defaults to the installed RTD theme assets under
#::             /opt/rtd/themes/wallpaper.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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
WALLPAPER_ROOT = Path("/opt/rtd/themes/wallpaper")
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}
PROFILES = (
    {
        "id": "win10-light",
        "name": "Windows 10 Light Mode",
        "summary": "A familiar light desktop layout with Windows-inspired panels, icons, and spacing.",
        "image": "profile-win10-light.jpg",
    },
    {
        "id": "win10-dark",
        "name": "Windows 10 Dark Mode",
        "summary": "A Windows-inspired profile tuned for darker rooms and lower desktop glare.",
        "image": "profile-win10-dark.jpg",
    },
    {
        "id": "mac-bright",
        "name": "Mac OS Bright",
        "summary": "A bright macOS-inspired profile with a dock-oriented workflow and clean surfaces.",
        "image": "profile-mac-bright.jpg",
    },
    {
        "id": "mac-dusk",
        "name": "Mac OS Dusk",
        "summary": "The macOS-inspired profile with darker colors and a more subdued desktop feel.",
        "image": "profile-mac-dusk.jpg",
    },
    {
        "id": "crisp-day",
        "name": "Crisp Day",
        "summary": "A clean professional profile tuned for day work, balanced contrast, and legibility.",
        "image": "profile-crisp-day.jpg",
    },
    {
        "id": "crisp-evening",
        "name": "Crisp Evening",
        "summary": "The crisp professional profile in a darker evening variant for extended sessions.",
        "image": "profile-crisp-evening.jpg",
    },
    {
        "id": "moca-smooth",
        "name": "Moca Smooth",
        "summary": "A warm, low-glare profile intended to reduce eye strain during long workdays.",
        "image": "profile-moca-smooth.jpg",
    },
    {
        "id": "distro-reset",
        "name": "Distribution Reset",
        "summary": "Reset GNOME appearance settings back toward the distribution defaults.",
        "image": "profile-distro-reset.jpg",
    },
)


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


def wallpapers():
    if not WALLPAPER_ROOT.is_dir():
        return []
    return sorted(
        (
            path
            for path in WALLPAPER_ROOT.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
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


def scaled_image(path, width, height):
    if not path.is_file():
        return Gtk.Image()
    pixels = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(path), width, height, True)
    return Gtk.Image.new_from_pixbuf(pixels)


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
        self.row(grid, 2, "Use RTD wallpaper", self.global_wallpaper_switch)
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
        if WALLPAPER_ROOT.is_dir():
            self.custom_wallpaper.set_current_folder(str(WALLPAPER_ROOT))

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
            "Select a complete workstation profile with a screenshot preview, then apply the matching RTD desktop look directly from this manager.",
        )

        profile_area = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        body.pack_start(profile_area, True, True, 0)

        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroller.set_min_content_width(270)
        self.profile_list = Gtk.ListBox()
        self.profile_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.profile_list.connect("row-selected", self.select_profile)
        scroller.add(self.profile_list)
        profile_area.pack1(scroller, resize=False, shrink=False)

        preview = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        preview.set_margin_start(18)
        profile_area.pack2(preview, resize=True, shrink=False)

        self.profile_preview = Gtk.Image()
        self.profile_preview.set_halign(Gtk.Align.CENTER)
        self.profile_preview.set_valign(Gtk.Align.START)
        preview.pack_start(self.profile_preview, False, False, 0)

        self.profile_title = Gtk.Label()
        self.profile_title.set_halign(Gtk.Align.START)
        self.profile_title.set_markup("<span size='large' weight='bold'>Select a profile</span>")
        preview.pack_start(self.profile_title, False, False, 0)

        self.profile_summary = Gtk.Label()
        self.profile_summary.set_halign(Gtk.Align.START)
        self.profile_summary.set_line_wrap(True)
        preview.pack_start(self.profile_summary, False, False, 0)

        note = Gtk.Label(
            label="Profiles may install theme assets, enable GNOME extensions, adjust panel behavior, and change user appearance settings. GNOME can require a logout and login before every Shell change is visible."
        )
        note.set_halign(Gtk.Align.START)
        note.set_line_wrap(True)
        preview.pack_start(note, False, False, 0)

        apply_button = Gtk.Button(label="Apply Selected Profile")
        apply_button.get_style_context().add_class("suggested-action")
        apply_button.connect("clicked", self.apply_selected_profile)
        preview.pack_end(apply_button, False, False, 0)

        for profile in PROFILES:
            self.profile_list.add(self.profile_row(profile))
        self.profile_list.show_all()
        first = self.profile_list.get_row_at_index(0)
        if first is not None:
            self.profile_list.select_row(first)
        return page

    def profile_row(self, profile):
        row = Gtk.ListBoxRow()
        row.profile = profile
        item = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        item.set_border_width(8)
        item.pack_start(scaled_image(APP_DIR / "Media_files" / profile["image"], 96, 58), False, False, 0)

        copy = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        title = Gtk.Label(label=profile["name"])
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("heading")
        summary = Gtk.Label(label=profile["summary"])
        summary.set_halign(Gtk.Align.START)
        summary.set_line_wrap(True)
        summary.set_max_width_chars(28)
        copy.pack_start(title, False, False, 0)
        copy.pack_start(summary, False, False, 0)
        item.pack_start(copy, True, True, 0)
        row.add(item)
        return row

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
        for path in wallpapers():
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

    def select_profile(self, _listbox, row):
        if row is None:
            return
        profile = row.profile
        image_path = APP_DIR / "Media_files" / profile["image"]
        if image_path.is_file():
            pixels = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(image_path), 500, 300, True)
            self.profile_preview.set_from_pixbuf(pixels)
        else:
            self.profile_preview.clear()
        self.profile_title.set_markup(f"<span size='large' weight='bold'>{profile['name']}</span>")
        self.profile_summary.set_text(profile["summary"])

    def apply_selected_profile(self, _button):
        row = self.profile_list.get_selected_row()
        if row is None:
            self.message("No profile selected", "Select an RTD desktop profile first.", Gtk.MessageType.WARNING)
            return
        profile = row.profile
        result = subprocess.run(
            [str(BACKEND), "--apply-profile", profile["id"]],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
        if result.returncode == 0:
            detail = result.stderr.strip() or f"{profile['name']} has been applied."
            self.message("Profile applied", detail, Gtk.MessageType.INFO)
        else:
            self.message("Could not apply profile", result.stderr.strip() or "The profile update failed.", Gtk.MessageType.ERROR)

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
