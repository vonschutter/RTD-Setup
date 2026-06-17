#!/usr/bin/env python3

#
#::  RTD User Backup GTK Frontend
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::
#::  INTERNAL FRONTEND
#::
#::  Purpose:
#::    Provide a user-facing GTK 3 interface for rtd-oem-backup-linux-config.
#::
#::  Notes:
#::    This helper is intentionally not named rtd-* so it is not exposed as a
#::    separate command. The Bash backend may launch it from the module folder
#::    or download it into the RTD cache for direct GitHub execution.
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

from __future__ import annotations

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Imports
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
from typing import Dict, List

try:
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gdk, GLib, Gtk, Pango
except (ImportError, ValueError) as error:
    raise SystemExit(f"RTD User Backup GUI requires GTK 3 Python bindings: {error}")


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Settings
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

APP_DIR = Path(__file__).resolve().parent
BACKEND = Path(os.environ.get("RTD_USER_BACKUP_BACKEND", APP_DIR / "rtd-oem-backup-linux-config"))


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Utility Functions
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def human_size(size: int) -> str:
    units = ("B", "KiB", "MiB", "GiB", "TiB")
    value = float(max(0, size))
    idx = 0
    while value >= 1024 and idx < len(units) - 1:
        value /= 1024
        idx += 1
    return f"{value:.1f} {units[idx]}" if idx else f"{int(value)} {units[idx]}"


def run_text(args: List[str]) -> str:
    result = subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return result.stdout


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Main Window
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

class BackupWindow(Gtk.Window):
    def __init__(self) -> None:
        super().__init__(title="RTD User Backup")
        self.set_default_size(1120, 760)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("destroy", self.on_destroy)
        self.process = None
        self.profiles: List[Dict[str, str]] = []
        self.profile_checks: Dict[str, Gtk.CheckButton] = {}
        self.passphrase_file = None

        self.build_css()
        self.add(self.build_window())
        self.load_profiles()
        self.show_all()

    def build_css(self) -> None:
        provider = Gtk.CssProvider()
        provider.load_from_data(
            b"""
            .header { background: #111827; border-bottom: 3px solid #0ea5e9; }
            .title { color: #f8fafc; font-size: 28px; font-weight: 700; }
            .subtitle { color: #cbd5e1; font-size: 13px; }
            .section-title { font-size: 16px; font-weight: 700; }
            .danger { color: #b91c1c; font-weight: 700; }
            .muted { color: #64748b; }
            textview { font-family: monospace; font-size: 10pt; }
            """
        )
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def build_window(self) -> Gtk.Widget:
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.pack_start(self.header(), False, False, 0)
        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=18)
        body.set_border_width(18)
        outer.pack_start(body, True, True, 0)

        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        left.set_size_request(440, -1)
        body.pack_start(left, False, False, 0)
        left.pack_start(self.profile_section(), True, True, 0)
        left.pack_start(self.destination_section(), False, False, 0)
        left.pack_start(self.encryption_section(), False, False, 0)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        body.pack_start(right, True, True, 0)
        right.pack_start(self.summary_section(), False, False, 0)
        right.pack_start(self.output_section(), True, True, 0)
        right.pack_start(self.actions(), False, False, 0)
        return outer

    def header(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.set_border_width(22)
        box.get_style_context().add_class("header")
        title = Gtk.Label(label="RunTime Data User Backup")
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("title")
        subtitle = Gtk.Label(label="Encrypted migration backups for home data, settings, browser profiles, and virtual machines.")
        subtitle.set_halign(Gtk.Align.START)
        subtitle.get_style_context().add_class("subtitle")
        box.pack_start(title, False, False, 0)
        box.pack_start(subtitle, False, False, 0)
        return box

    def section_title(self, text: str) -> Gtk.Label:
        label = Gtk.Label(label=text)
        label.set_halign(Gtk.Align.START)
        label.get_style_context().add_class("section-title")
        return label

    def profile_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.pack_start(self.section_title("Backup Profiles"), False, False, 0)
        self.profile_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroller.add(self.profile_box)
        box.pack_start(scroller, True, True, 0)
        return box

    def destination_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.pack_start(self.section_title("Destination"), False, False, 0)
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.destination_entry = Gtk.Entry()
        self.destination_entry.set_placeholder_text("External drive or mounted network folder")
        row.pack_start(self.destination_entry, True, True, 0)
        browse = Gtk.Button(label="Browse")
        browse.connect("clicked", self.on_browse_destination)
        row.pack_start(browse, False, False, 0)
        box.pack_start(row, False, False, 0)
        return box

    def encryption_section(self) -> Gtk.Widget:
        grid = Gtk.Grid(column_spacing=10, row_spacing=8)
        grid.attach(self.section_title("Encryption"), 0, 0, 2, 1)
        self.passphrase = Gtk.Entry()
        self.passphrase.set_visibility(False)
        self.passphrase.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self.passphrase_confirm = Gtk.Entry()
        self.passphrase_confirm.set_visibility(False)
        self.passphrase_confirm.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self.compression = Gtk.SpinButton(adjustment=Gtk.Adjustment(value=10, lower=1, upper=19, step_increment=1), digits=0)
        self.compression.set_numeric(True)
        self.add_row(grid, 1, "Passphrase", self.passphrase)
        self.add_row(grid, 2, "Confirm", self.passphrase_confirm)
        self.add_row(grid, 3, "Compression", self.compression)
        warning = Gtk.Label(label="Keep the passphrase. Lost passphrases cannot be recovered.")
        warning.set_halign(Gtk.Align.START)
        warning.get_style_context().add_class("danger")
        grid.attach(warning, 0, 4, 2, 1)
        return grid

    def add_row(self, grid: Gtk.Grid, row: int, label: str, widget: Gtk.Widget) -> None:
        text = Gtk.Label(label=label)
        text.set_halign(Gtk.Align.START)
        grid.attach(text, 0, row, 1, 1)
        grid.attach(widget, 1, row, 1, 1)

    def summary_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.pack_start(self.section_title("Review"), False, False, 0)
        self.summary = Gtk.Label(label="Select profiles and destination.")
        self.summary.set_halign(Gtk.Align.START)
        self.summary.set_line_wrap(True)
        box.pack_start(self.summary, False, False, 0)
        estimate = Gtk.Button(label="Estimate Size")
        estimate.connect("clicked", self.on_estimate)
        box.pack_start(estimate, False, False, 0)
        return box

    def output_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.status = Gtk.Label(label="Ready")
        self.status.set_halign(Gtk.Align.START)
        box.pack_start(self.status, False, False, 0)
        self.progress = Gtk.ProgressBar()
        self.progress.set_show_text(True)
        box.pack_start(self.progress, False, False, 0)
        self.output = Gtk.TextView()
        self.output.set_editable(False)
        self.output.set_cursor_visible(False)
        self.output.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.output.modify_font(Pango.FontDescription("monospace 10"))
        scroller = Gtk.ScrolledWindow()
        scroller.add(self.output)
        box.pack_start(scroller, True, True, 0)
        return box

    def actions(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.run_button = Gtk.Button(label="Start Backup")
        self.run_button.connect("clicked", self.on_start_backup)
        self.cancel_button = Gtk.Button(label="Cancel")
        self.cancel_button.set_sensitive(False)
        self.cancel_button.connect("clicked", self.on_cancel)
        box.pack_end(self.run_button, False, False, 0)
        box.pack_end(self.cancel_button, False, False, 0)
        return box

    def load_profiles(self) -> None:
        try:
            output = run_text([str(BACKEND), "--no-gui", "--list-profiles"])
        except Exception as error:
            self.status.set_text(f"Unable to load profiles: {error}")
            return
        for line in output.splitlines():
            parts = line.split("\t")
            if len(parts) != 4:
                continue
            profile = {"id": parts[0], "label": parts[1], "summary": parts[2], "root": parts[3]}
            self.profiles.append(profile)
            check = Gtk.CheckButton(label=f"{profile['label']} - {profile['summary']}")
            check.set_tooltip_text(profile["id"])
            check.connect("toggled", lambda _button: self.update_summary())
            self.profile_checks[profile["id"]] = check
            self.profile_box.pack_start(check, False, False, 0)
        self.update_summary()

    def selected_profiles(self) -> List[str]:
        return [pid for pid, check in self.profile_checks.items() if check.get_active()]

    def update_summary(self) -> None:
        profiles = self.selected_profiles()
        destination = self.destination_entry.get_text().strip()
        self.summary.set_text(
            f"Profiles selected: {len(profiles)}\nDestination: {destination or 'not selected'}\nArchive format: tar + zstd + GPG AES256"
        )

    def on_browse_destination(self, _button: Gtk.Button) -> None:
        dialog = Gtk.FileChooserDialog(title="Select Backup Destination", transient_for=self, action=Gtk.FileChooserAction.SELECT_FOLDER)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK)
        try:
            if dialog.run() == Gtk.ResponseType.OK:
                self.destination_entry.set_text(dialog.get_filename() or "")
                self.update_summary()
        finally:
            dialog.destroy()

    def base_backend_args(self) -> List[str]:
        profiles = ",".join(self.selected_profiles())
        return [
            str(BACKEND),
            "--no-gui",
            "--profiles",
            profiles,
            "--user-home",
            str(Path.home()),
            "--backup-user",
            os.environ.get("USER", ""),
        ]

    def on_estimate(self, _button: Gtk.Button) -> None:
        if not self.selected_profiles():
            self.status.set_text("Select at least one profile.")
            return
        try:
            output = run_text([*self.base_backend_args(), "--estimate"])
            self.status.set_text(f"Estimated source size: {human_size(int(output.strip() or '0'))}")
        except Exception as error:
            self.status.set_text(f"Estimate failed: {error}")

    def validate(self) -> bool:
        if not self.selected_profiles():
            self.status.set_text("Select at least one profile.")
            return False
        if not self.destination_entry.get_text().strip():
            self.status.set_text("Select a destination.")
            return False
        if self.passphrase.get_text() != self.passphrase_confirm.get_text():
            self.status.set_text("Passphrases do not match.")
            return False
        if len(self.passphrase.get_text()) < 8:
            self.status.set_text("Use a passphrase with at least 8 characters.")
            return False
        return True

    def write_passphrase_file(self) -> str:
        fd, path = tempfile.mkstemp(prefix="rtd-backup-pass.", text=True)
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as handle:
            handle.write(self.passphrase.get_text())
        self.passphrase_file = path
        return path

    def on_start_backup(self, _button: Gtk.Button) -> None:
        if not self.validate():
            return
        pass_file = self.write_passphrase_file()
        cmd = [
            *self.base_backend_args(),
            "--backup",
            "--destination",
            self.destination_entry.get_text().strip(),
            "--passphrase-file",
            pass_file,
            "--compression-level",
            str(int(self.compression.get_value())),
        ]
        if "kvm" in self.selected_profiles() and os.geteuid() != 0:
            if shutil.which("pkexec"):
                cmd = ["pkexec", "env", f"HOME={Path.home()}", f"USER={os.environ.get('USER','')}", *cmd]
            elif shutil.which("sudo"):
                cmd = ["sudo", "-E", *cmd]
        self.output.get_buffer().set_text("")
        self.append_output("$ " + " ".join(shlex.quote(part) for part in cmd) + "\n\n")
        self.run_button.set_sensitive(False)
        self.cancel_button.set_sensitive(True)
        self.progress.set_fraction(0)
        self.status.set_text("Starting backup...")
        try:
            self.process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        except OSError as error:
            self.status.set_text(f"Failed to start backup: {error}")
            self.cleanup_passphrase()
            return
        threading.Thread(target=self.reader, daemon=True).start()

    def append_output(self, text: str) -> None:
        buffer = self.output.get_buffer()
        buffer.insert(buffer.get_end_iter(), text)
        mark = buffer.create_mark(None, buffer.get_end_iter(), False)
        self.output.scroll_mark_onscreen(mark)

    def handle_progress(self, line: str) -> bool:
        if not line.startswith("RTD_PROGRESS "):
            return False
        fields = {}
        for part in shlex.split(line)[1:]:
            if "=" in part:
                key, value = part.split("=", 1)
                fields[key] = value
        try:
            pct = max(0, min(100, int(fields.get("percent", "0"))))
        except ValueError:
            return True
        self.progress.set_fraction(pct / 100)
        self.progress.set_text(f"{pct}%")
        self.status.set_text(fields.get("current", f"Backup {pct}%"))
        return True

    def reader(self) -> None:
        process = self.process
        if not process or not process.stdout:
            GLib.idle_add(self.on_complete, 1)
            return
        for line in process.stdout:
            GLib.idle_add(self.on_line, line)
        rc = process.wait()
        GLib.idle_add(self.on_complete, rc)

    def on_line(self, line: str) -> bool:
        clean = line.replace("\r", "\n")
        if not self.handle_progress(clean.strip()):
            self.append_output(clean)
        return False

    def on_complete(self, rc: int) -> bool:
        self.append_output(f"\nBackend exited with status {rc}\n")
        self.status.set_text("Backup complete" if rc == 0 else f"Backup failed with status {rc}")
        if rc == 0:
            self.progress.set_fraction(1.0)
            self.progress.set_text("100%")
        self.process = None
        self.run_button.set_sensitive(True)
        self.cancel_button.set_sensitive(False)
        self.cleanup_passphrase()
        return False

    def cleanup_passphrase(self) -> None:
        if self.passphrase_file:
            try:
                os.remove(self.passphrase_file)
            except OSError:
                pass
            self.passphrase_file = None

    def on_cancel(self, _button: Gtk.Button) -> None:
        if self.process and self.process.poll() is None:
            self.process.terminate()
            self.status.set_text("Cancel requested")

    def on_destroy(self, *_args) -> None:
        if self.process and self.process.poll() is None:
            self.process.terminate()
        self.cleanup_passphrase()
        Gtk.main_quit()


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Executive
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def main() -> int:
    BackupWindow()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
