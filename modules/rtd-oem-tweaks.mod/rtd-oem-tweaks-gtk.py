#!/usr/bin/env python3
#
#::                                       A D M I N   T O O L
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::// RTD OEM GNOME Tweaks GTK Frontend //::::::::::::::::::::::// Linux //:::::::::
#:: Author(s):    RTD
#:: Version:      1.13
#::
#:: Purpose:      Provide a GTK frontend for the RTD OEM GNOME Tweaks backend.
#::               It displays available tweaks, profiles, and status in a desktop GUI.
#::
#:: Value:        Makes the OEM tweak workflow easier to scan and operate than a
#::               terminal checklist while keeping the Bash backend as the source
#::               of truth for applying settings and reporting status.
#::
#:: Usage:        Run the frontend to open the graphical tweak manager.
#::               Select tweaks or profiles, then apply them through the interface.
#::
#:: Examples:
#::               rtd-oem-tweaks-gtk.py
#::               ./rtd-oem-tweaks-gtk.py
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

"""GTK frontend for RTD OEM Tweaks."""

from pathlib import Path
import os
import subprocess
import sys

try:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import GdkPixbuf, Gtk
except (ImportError, ValueError) as error:
    raise SystemExit(
        "RTD OEM Tweaks requires GTK 3 Python bindings (python3-gi): "
        f"{error}"
    )


APP_DIR = Path(__file__).resolve().parent
LINK_DIR = Path(__file__).parent
BACKEND = APP_DIR / "rtd-oem-tweaks"
PROFILE_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "rtd" / "oem-tweak-profiles"
ADVANCED_CATEGORIES = {"Advanced"}


def first_existing_path(*paths):
    for path in paths:
        if path.is_file():
            return path
    return None


BANNER = first_existing_path(
    APP_DIR / "Media_files" / "rtd-oem-tweaks-banner.svg",
    LINK_DIR / "Media_files" / "rtd-oem-tweaks-banner.svg",
    Path("/opt/rtd/modules/rtd-oem-tweaks.mod/Media_files/rtd-oem-tweaks-banner.svg"),
    Path.home() / "GIT/RTD-Setup/modules/rtd-oem-tweaks.mod/Media_files/rtd-oem-tweaks-banner.svg",
    Path.home() / "RTD-Setup/modules/rtd-oem-tweaks.mod/Media_files/rtd-oem-tweaks-banner.svg",
)


class Tweak:
    def __init__(self, tweak_id, category, status, title, description):
        self.id = tweak_id
        self.category = category
        self.status = status
        self.title = title
        self.description = description


def run_backend(*args):
    return subprocess.run(
        [str(BACKEND), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def safe_profile_name(name):
    return "".join(char if char.isalnum() or char in "_.-" else "_" for char in name).strip("_")


class TweakWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="RTD OEM Tweaks")
        self.set_default_size(1100, 720)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("destroy", Gtk.main_quit)

        self.tweaks = []
        self.rows = {}
        self.switches = {}
        self.category_buttons = {}
        self.selected_ids = set()
        self.profile_list = None
        self.profile_selection = None
        self.search_text = ""

        self.load_css()
        self.add(self.build_window())
        self.refresh_tweaks()
        self.show_all()

    def load_css(self):
        css = b"""
        .header {
            background: #263b4d;
            color: white;
        }
        .app-title {
            color: white;
            font-size: 28px;
            font-weight: 700;
        }
        .app-subtitle {
            color: #d7e8ff;
            font-size: 14px;
        }
        .section-title {
            font-size: 20px;
            font-weight: 700;
        }
        .status-applied {
            color: #1b7f3a;
            font-weight: 700;
        }
        .status-pending {
            color: #8a5a00;
            font-weight: 700;
        }
        .muted {
            color: #666666;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def build_window(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.pack_start(self.build_header(), False, False, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        body.pack_start(self.build_sidebar(), False, False, 0)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(180)
        body.pack_start(self.stack, True, True, 0)
        outer.pack_start(body, True, True, 0)

        outer.pack_end(self.build_footer(), False, False, 0)
        return outer

    def build_header(self):
        overlay = Gtk.Overlay()

        if BANNER is not None:
            try:
                pixels = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(BANNER), 1100, 170, False)
                overlay.add(Gtk.Image.new_from_pixbuf(pixels))
                return overlay
            except Exception:
                pass

        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        header.set_size_request(-1, 170)
        header.set_border_width(24)
        header.get_style_context().add_class("header")
        overlay.add(header)

        title = Gtk.Label(label="RTD OEM Tweaks")
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("app-title")
        header.pack_start(title, False, False, 0)

        subtitle = Gtk.Label(
            label="Choose practical desktop improvements, apply them, and save reusable profiles."
        )
        subtitle.set_halign(Gtk.Align.START)
        subtitle.set_line_wrap(True)
        subtitle.get_style_context().add_class("app-subtitle")
        header.pack_start(subtitle, False, False, 0)
        return overlay

    def build_sidebar(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.set_border_width(14)
        box.set_size_request(230, -1)

        label = Gtk.Label(label="Categories")
        label.set_halign(Gtk.Align.START)
        label.get_style_context().add_class("section-title")
        box.pack_start(label, False, False, 4)

        self.category_list = Gtk.ListBox()
        self.category_list.set_selection_mode(Gtk.SelectionMode.NONE)

        search = Gtk.SearchEntry()
        search.set_placeholder_text("Search tweaks")
        search.connect("search-changed", self.on_search_changed)
        box.pack_start(search, False, False, 6)
        box.pack_start(self.category_list, True, True, 0)
        return box

    def build_footer(self):
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        footer.set_border_width(14)

        self.summary = Gtk.Label(label="Ready.")
        self.summary.set_halign(Gtk.Align.START)
        footer.pack_start(self.summary, True, True, 0)

        refresh = Gtk.Button(label="Refresh Status")
        refresh.connect("clicked", lambda _button: self.refresh_tweaks(preserve_desired=False))
        footer.pack_end(refresh, False, False, 0)

        apply = Gtk.Button(label="Apply Changes")
        apply.get_style_context().add_class("suggested-action")
        apply.connect("clicked", self.apply_changes)
        footer.pack_end(apply, False, False, 0)
        return footer

    def load_tweaks(self):
        result = run_backend("--list-tweaks")
        if result.returncode != 0:
            self.show_error("Unable to read tweak list.", result.stderr.strip())
            return []
        tweaks = []
        for line in result.stdout.splitlines():
            parts = line.split("\t", 4)
            if len(parts) != 5:
                continue
            tweaks.append(Tweak(*parts))
        return tweaks

    def refresh_tweaks(self, preserve_desired=True):
        had_state = bool(self.tweaks or self.selected_ids)
        self.tweaks = self.load_tweaks()
        valid_ids = {tweak.id for tweak in self.tweaks}
        applied_ids = {tweak.id for tweak in self.tweaks if tweak.status == "Applied"}
        if preserve_desired and had_state:
            self.selected_ids.intersection_update(valid_ids)
        else:
            self.selected_ids = applied_ids
        self.rebuild_pages()
        self.summary.set_text(f"Loaded {len(self.tweaks)} tweak options.")

    def rebuild_pages(self):
        self.rows.clear()
        self.switches.clear()
        self.category_buttons.clear()

        for child in self.category_list.get_children():
            self.category_list.remove(child)
        for child in self.stack.get_children():
            self.stack.remove(child)

        categories = []
        for tweak in self.tweaks:
            if not self.tweak_matches_search(tweak):
                continue
            if tweak.category not in categories:
                categories.append(tweak.category)
        categories = [category for category in categories if category not in ADVANCED_CATEGORIES] + [
            category for category in categories if category in ADVANCED_CATEGORIES
        ]

        for index, category in enumerate(categories):
            self.add_category_page(category)
            button = Gtk.Button(label=category)
            button.set_halign(Gtk.Align.FILL)
            button.connect("clicked", self.show_category, category)
            row = Gtk.ListBoxRow()
            row.add(button)
            self.category_list.add(row)
            self.category_buttons[category] = button
            if index == 0:
                self.stack.set_visible_child_name(category)

        self.add_profiles_page()
        profile_button = Gtk.Button(label="Profiles")
        profile_button.set_halign(Gtk.Align.FILL)
        profile_button.connect("clicked", self.show_category, "Profiles")
        row = Gtk.ListBoxRow()
        row.add(profile_button)
        self.category_list.add(row)
        self.category_buttons["Profiles"] = profile_button

        self.category_list.show_all()
        self.stack.show_all()

    def add_category_page(self, category):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        page.set_border_width(22)

        title = Gtk.Label(label=category)
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("section-title")
        page.pack_start(title, False, False, 0)

        description = Gtk.Label(label=self.category_description(category))
        description.set_halign(Gtk.Align.START)
        description.set_line_wrap(True)
        description.get_style_context().add_class("muted")
        page.pack_start(description, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        scroll.add(listbox)
        page.pack_start(scroll, True, True, 0)

        for tweak in [item for item in self.tweaks if item.category == category]:
            if not self.tweak_matches_search(tweak):
                continue
            row = self.build_tweak_row(tweak, tweak.id in self.selected_ids)
            listbox.add(row)

        self.stack.add_named(page, category)

    def on_search_changed(self, entry):
        self.search_text = entry.get_text().strip().casefold()
        self.rebuild_pages()

    def tweak_matches_search(self, tweak):
        if not self.search_text:
            return True
        haystack = " ".join(
            (tweak.id, tweak.category, tweak.title, tweak.description, tweak.status)
        ).casefold()
        return self.search_text in haystack

    def category_description(self, category):
        descriptions = {
            "Usability": "Small changes that make GNOME easier to operate day to day.",
            "Files": "File manager and file chooser behavior.",
            "Overview": "Application overview organization and app categories.",
            "Extensions": "Baseline GNOME Shell extension choices.",
            "Power": "Laptop and workstation power behavior.",
            "Panel": "Top bar, clock, battery, and panel defaults.",
            "Fonts": "Text rendering and smoothing.",
            "Terminal": "Terminal and Tilix defaults.",
            "Dock": "Dock positioning, indicators, and behavior.",
            "Startup": "Login sound behavior.",
            "Advanced": "Special-purpose maintenance and custom values.",
        }
        return descriptions.get(category, "Desktop tweak options.")

    def build_tweak_row(self, tweak, active):
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        box.set_border_width(12)

        switch = Gtk.Switch()
        switch.set_valign(Gtk.Align.CENTER)
        switch.set_active(active)
        switch.connect("notify::active", self.on_tweak_switch_changed, tweak.id)
        self.switches[tweak.id] = switch
        box.pack_start(switch, False, False, 0)

        copy = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title = Gtk.Label(label=tweak.title)
        title.set_halign(Gtk.Align.START)
        title.set_line_wrap(True)
        copy.pack_start(title, False, False, 0)

        description = Gtk.Label(label=tweak.description)
        description.set_halign(Gtk.Align.START)
        description.set_line_wrap(True)
        description.get_style_context().add_class("muted")
        copy.pack_start(description, False, False, 0)
        box.pack_start(copy, True, True, 0)

        status = Gtk.Label(label=tweak.status)
        status.set_valign(Gtk.Align.CENTER)
        status.get_style_context().add_class(
            "status-applied" if tweak.status == "Applied" else "status-pending"
        )
        box.pack_end(status, False, False, 0)

        row.add(box)
        return row

    def add_profiles_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        page.set_border_width(22)

        title = Gtk.Label(label="Profiles")
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("section-title")
        page.pack_start(title, False, False, 0)

        copy = Gtk.Label(
            label=(
                "Profiles are saved groups of tweaks. They are stored as simple text files "
                f"in {PROFILE_DIR}."
            )
        )
        copy.set_halign(Gtk.Align.START)
        copy.set_line_wrap(True)
        copy.get_style_context().add_class("muted")
        page.pack_start(copy, False, False, 0)

        self.profile_list = Gtk.ListBox()
        self.profile_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.profile_list)
        page.pack_start(scroll, True, True, 0)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        save = Gtk.Button(label="Save Enabled as Profile")
        save.connect("clicked", self.save_profile)
        actions.pack_start(save, False, False, 0)
        load = Gtk.Button(label="Load Profile")
        load.connect("clicked", self.load_profile)
        actions.pack_start(load, False, False, 0)
        apply = Gtk.Button(label="Apply Profile")
        apply.connect("clicked", self.apply_profile)
        actions.pack_start(apply, False, False, 0)
        delete = Gtk.Button(label="Delete Profile")
        delete.connect("clicked", self.delete_profile)
        actions.pack_start(delete, False, False, 0)
        page.pack_start(actions, False, False, 0)

        self.stack.add_named(page, "Profiles")
        self.refresh_profiles()

    def refresh_profiles(self):
        if self.profile_list is None:
            return
        for child in self.profile_list.get_children():
            self.profile_list.remove(child)

        result = run_backend("--list-profiles")
        profiles = []
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                parts = line.split("\t", 1)
                if len(parts) == 2:
                    profiles.append(parts)

        if not profiles:
            row = Gtk.ListBoxRow()
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            box.set_border_width(12)
            label = Gtk.Label(label="No profiles saved yet.")
            label.set_halign(Gtk.Align.START)
            box.pack_start(label, False, False, 0)
            row.add(box)
            row.profile_name = None
            self.profile_list.add(row)
        else:
            for name, path in profiles:
                row = Gtk.ListBoxRow()
                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
                box.set_border_width(12)
                label = Gtk.Label(label=name)
                label.set_halign(Gtk.Align.START)
                detail = Gtk.Label(label=path)
                detail.set_halign(Gtk.Align.START)
                detail.get_style_context().add_class("muted")
                box.pack_start(label, False, False, 0)
                box.pack_start(detail, False, False, 0)
                row.add(box)
                row.profile_name = name
                self.profile_list.add(row)
        self.profile_list.show_all()

    def selected_profile(self):
        row = self.profile_list.get_selected_row() if self.profile_list else None
        return getattr(row, "profile_name", None)

    def selected_tweak_ids(self):
        return [tweak.id for tweak in self.tweaks if tweak.id in self.selected_ids]

    def on_tweak_switch_changed(self, switch, _param, tweak_id):
        if switch.get_active():
            self.selected_ids.add(tweak_id)
        else:
            self.selected_ids.discard(tweak_id)

    def show_category(self, _button, category):
        self.stack.set_visible_child_name(category)

    def pending_changes(self):
        changes = []
        for tweak in self.tweaks:
            desired = tweak.id in self.selected_ids
            applied = tweak.status == "Applied"
            if desired != applied:
                changes.append((tweak, "on" if desired else "off"))
        return changes

    def apply_changes(self, _button):
        changes = self.pending_changes()
        if not changes:
            self.show_info("No changes", "All toggles already match the current tweak status.")
            return
        failures = []
        canceled = False
        for tweak, state in changes:
            result = run_backend("--set", tweak.id, state)
            if result.returncode == 0:
                continue
            if result.returncode == 130:
                canceled = True
                break
            detail = result.stderr.strip() or result.stdout.strip()
            failures.append(f"{tweak.title}: {detail or 'No details were provided.'}")

        self.refresh_tweaks(preserve_desired=False)
        if canceled:
            self.show_info("Canceled", "No further changes were applied.")
        elif failures:
            self.show_error("Some changes failed", "\n".join(failures))
        else:
            self.show_info("Changes applied", f"Updated {len(changes)} tweak(s).")

    def save_profile(self, _button):
        selected = self.selected_tweak_ids()
        if not selected:
            self.show_info("Nothing enabled", "Turn on one or more toggles before saving a profile.")
            return
        dialog = Gtk.Dialog(title="Save Profile", transient_for=self, modal=True)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Save", Gtk.ResponseType.OK)
        box = dialog.get_content_area()
        box.set_border_width(14)
        entry = Gtk.Entry()
        entry.set_text("workstation-default")
        box.pack_start(Gtk.Label(label="Profile name"), False, False, 4)
        box.pack_start(entry, False, False, 4)
        dialog.show_all()
        response = dialog.run()
        name = safe_profile_name(entry.get_text())
        dialog.destroy()
        if response != Gtk.ResponseType.OK:
            return
        if not name:
            self.show_error("Invalid profile name", "Profile name cannot be empty.")
            return
        PROFILE_DIR.mkdir(parents=True, exist_ok=True)
        profile_file = PROFILE_DIR / f"{name}.profile"
        profile_file.write_text(
            "# RTD OEM Tweaks profile\n"
            f"# name={name}\n"
            + "\n".join(selected)
            + "\n",
            encoding="utf-8",
        )
        self.refresh_profiles()
        self.show_info("Profile saved", f"Saved {name} with {len(selected)} tweak(s).")

    def load_profile(self, _button):
        name = self.selected_profile()
        if not name:
            self.show_info("No profile selected", "Select a profile first.")
            return
        profile_file = PROFILE_DIR / f"{name}.profile"
        try:
            keys = [
                line.strip()
                for line in profile_file.read_text(encoding="utf-8").splitlines()
                if line.strip() and not line.startswith("#")
            ]
        except OSError as error:
            self.show_error("Unable to load profile", str(error))
            return
        valid_ids = {tweak.id for tweak in self.tweaks}
        self.selected_ids = {key for key in keys if key in valid_ids}
        self.rebuild_pages()
        self.show_info(
            "Profile loaded",
            f"Selected {len(self.selected_ids)} tweak(s) from {name}.",
        )

    def apply_profile(self, _button):
        name = self.selected_profile()
        if not name:
            self.show_info("No profile selected", "Select a profile first.")
            return
        self.load_profile(_button)
        self.apply_changes(_button)

    def delete_profile(self, _button):
        name = self.selected_profile()
        if not name:
            self.show_info("No profile selected", "Select a profile first.")
            return
        profile_file = PROFILE_DIR / f"{name}.profile"
        try:
            profile_file.unlink()
        except OSError as error:
            self.show_error("Unable to delete profile", str(error))
            return
        self.refresh_profiles()
        self.show_info("Profile deleted", f"Deleted profile {name}.")

    def show_info(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def show_error(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(message or "No details were provided.")
        dialog.run()
        dialog.destroy()


def main():
    if not BACKEND.exists():
        print(f"Backend not found: {BACKEND}", file=sys.stderr)
        return 1
    app = TweakWindow()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
