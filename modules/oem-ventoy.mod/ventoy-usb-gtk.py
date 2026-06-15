#!/usr/bin/env python3

#
#::                          RTD Ventoy USB GTK Frontend
#::                     G R A P H I C A L    F R O N T E N D
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#:: Module:     oem-ventoy.mod
#:: Script:     ventoy-usb-gtk.py
#:: Author(s):  RTD Team
#:: Version:    1.0
#::
#:: Purpose:    Provides a GTK frontend for the rtd-ventoy-usb backend. The UI
#::             exposes the create, update, and ISO sync workflows, discovers
#::             removable USB devices, streams backend output, and parses
#::             RTD_PROGRESS records for live progress updates.
#::
#:: Runtime:    This frontend does not perform privileged disk operations itself.
#::             It invokes the sibling rtd-ventoy-usb backend with --no-gui and
#::             requests privilege through pkexec when needed.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import threading
from typing import Dict, List, Optional

try:
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gdk, GLib, Gtk, Pango
except (ImportError, ValueError) as error:
    raise SystemExit(f"RTD Ventoy USB GUI requires GTK 3 Python bindings: {error}")


APP_DIR = Path(__file__).resolve().parent
BACKEND = APP_DIR / "rtd-ventoy-usb"
TERMINAL_ESCAPE_RE = re.compile(
    r"\x1b(?:"
    r"\[[0-?]*[A-Za-z@^_`{}~]|"
    r"\][^\x07]*(?:\x07|\x1b\\)|"
    r"[()][A-Za-z0-9]|"
    r"[@-Z\\-_]"
    r")"
)


def sanitize(text: str) -> str:
    return TERMINAL_ESCAPE_RE.sub("", text).replace("\r", "\n")


def human_size(value: object) -> str:
    try:
        size = float(value)
    except (TypeError, ValueError):
        return "unknown"
    units = ("B", "KiB", "MiB", "GiB", "TiB")
    idx = 0
    while size >= 1024 and idx < len(units) - 1:
        size /= 1024
        idx += 1
    return f"{size:.1f} {units[idx]}" if idx else f"{int(size)} {units[idx]}"


def removable_devices() -> List[Dict[str, str]]:
    try:
        result = subprocess.run(
            [
                "lsblk",
                "-J",
                "-b",
                "-o",
                "NAME,PATH,SIZE,VENDOR,MODEL,TRAN,RM,HOTPLUG,TYPE,MOUNTPOINT,FSTYPE,LABEL",
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        data = json.loads(result.stdout)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return []

    devices = []
    for item in data.get("blockdevices", []):
        if item.get("type") != "disk":
            continue
        tran = str(item.get("tran") or "")
        rm = str(item.get("rm") or "0")
        hotplug = str(item.get("hotplug") or "0")
        if tran != "usb" and rm != "1" and hotplug != "1":
            continue
        label = " ".join(str(item.get(k) or "").strip() for k in ("vendor", "model")).strip()
        devices.append(
            {
                "path": str(item.get("path") or f"/dev/{item.get('name', '')}"),
                "label": label or "Unknown USB device",
                "size": human_size(item.get("size")),
                "transport": tran or ("removable" if rm == "1" else "hotplug"),
            }
        )
    return devices


class VentoyWindow(Gtk.Window):
    def __init__(self) -> None:
        super().__init__(title="RTD Ventoy USB Creator")
        self.set_default_size(1120, 760)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("destroy", self.on_destroy)

        self.process: Optional[subprocess.Popen[str]] = None
        self.devices: List[Dict[str, str]] = []
        self.sources: List[str] = []

        self.build_css()
        self.add(self.build_window())
        self.refresh_devices()
        self.refresh_command_preview()
        self.show_all()

    def build_css(self) -> None:
        provider = Gtk.CssProvider()
        provider.load_from_data(
            b"""
            .title { font-size: 28px; font-weight: 700; color: #f8fafc; }
            .subtitle { font-size: 13px; color: #cbd5e1; }
            .header { background: #111827; border-bottom: 3px solid #0ea5e9; }
            .section-title { font-size: 16px; font-weight: 700; }
            .danger { color: #b91c1c; font-weight: 700; }
            .muted { color: #64748b; }
            .run-button { font-weight: 700; }
            textview { font-family: monospace; font-size: 10pt; }
            """
        )
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

    def build_window(self) -> Gtk.Widget:
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.pack_start(self.build_header(), False, False, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=18)
        body.set_border_width(18)
        outer.pack_start(body, True, True, 0)

        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        left.set_size_request(390, -1)
        body.pack_start(left, False, False, 0)
        left.pack_start(self.build_device_section(), False, False, 0)
        left.pack_start(self.build_workflow_section(), False, False, 0)
        left.pack_start(self.build_options_section(), False, False, 0)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        body.pack_start(right, True, True, 0)
        right.pack_start(self.build_sources_section(), False, False, 0)
        right.pack_start(self.build_progress_section(), True, True, 0)
        right.pack_start(self.build_actions(), False, False, 0)
        return outer

    def build_header(self) -> Gtk.Widget:
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        header.set_border_width(22)
        header.get_style_context().add_class("header")
        title = Gtk.Label(label="RunTime Data Ventoy USB")
        title.set_halign(Gtk.Align.START)
        title.get_style_context().add_class("title")
        subtitle = Gtk.Label(label="Create, update, and refresh multi-ISO Ventoy media.")
        subtitle.set_halign(Gtk.Align.START)
        subtitle.get_style_context().add_class("subtitle")
        header.pack_start(title, False, False, 0)
        header.pack_start(subtitle, False, False, 0)
        return header

    def section_title(self, text: str) -> Gtk.Label:
        label = Gtk.Label(label=text)
        label.set_halign(Gtk.Align.START)
        label.get_style_context().add_class("section-title")
        return label

    def build_device_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        top.pack_start(self.section_title("USB Device"), True, True, 0)
        refresh = Gtk.Button(label="Refresh")
        refresh.connect("clicked", lambda _button: self.refresh_devices())
        top.pack_start(refresh, False, False, 0)
        box.pack_start(top, False, False, 0)

        self.device_combo = Gtk.ComboBoxText()
        self.device_combo.connect("changed", lambda _combo: self.refresh_command_preview())
        box.pack_start(self.device_combo, False, False, 0)

        self.device_details = Gtk.Label()
        self.device_details.set_halign(Gtk.Align.START)
        self.device_details.set_line_wrap(True)
        self.device_details.get_style_context().add_class("muted")
        box.pack_start(self.device_details, False, False, 0)
        return box

    def build_workflow_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.pack_start(self.section_title("Workflow"), False, False, 0)
        self.action_create = Gtk.RadioButton.new_with_label_from_widget(None, "Create USB")
        self.action_sync = Gtk.RadioButton.new_with_label_from_widget(self.action_create, "Add or refresh ISOs")
        self.action_update = Gtk.RadioButton.new_with_label_from_widget(self.action_create, "Update Ventoy")
        self.action_sync.set_active(True)
        for button in (self.action_create, self.action_sync, self.action_update):
            button.connect("toggled", lambda _button: self.refresh_command_preview())
            box.pack_start(button, False, False, 0)
        warning = Gtk.Label(label="Create USB erases the selected device.")
        warning.set_halign(Gtk.Align.START)
        warning.get_style_context().add_class("danger")
        box.pack_start(warning, False, False, 0)
        return box

    def build_options_section(self) -> Gtk.Widget:
        grid = Gtk.Grid(column_spacing=10, row_spacing=8)
        grid.attach(self.section_title("Options"), 0, 0, 2, 1)

        self.version_entry = Gtk.Entry()
        self.version_entry.set_text("latest")
        self.version_entry.connect("changed", lambda _entry: self.refresh_command_preview())
        self.add_row(grid, 1, "Ventoy version", self.version_entry)

        self.partition_combo = Gtk.ComboBoxText()
        self.partition_combo.append("mbr", "MBR")
        self.partition_combo.append("gpt", "GPT")
        self.partition_combo.set_active_id("mbr")
        self.partition_combo.connect("changed", lambda _combo: self.refresh_command_preview())
        self.add_row(grid, 2, "Partition style", self.partition_combo)

        reserve_adjustment = Gtk.Adjustment(value=0, lower=0, upper=4096, step_increment=1)
        self.reserve_spin = Gtk.SpinButton(adjustment=reserve_adjustment, climb_rate=1, digits=0)
        self.reserve_spin.set_numeric(True)
        self.reserve_spin.connect("value-changed", lambda _spin: self.refresh_command_preview())
        self.add_row(grid, 3, "Reserve MiB", self.reserve_spin)

        self.overwrite_switch = Gtk.Switch()
        self.overwrite_switch.set_halign(Gtk.Align.START)
        self.overwrite_switch.connect("notify::active", lambda *_args: self.refresh_command_preview())
        self.add_row(grid, 4, "Overwrite ISOs", self.overwrite_switch)
        return grid

    def add_row(self, grid: Gtk.Grid, row: int, label: str, control: Gtk.Widget) -> None:
        text = Gtk.Label(label=label)
        text.set_halign(Gtk.Align.START)
        grid.attach(text, 0, row, 1, 1)
        grid.attach(control, 1, row, 1, 1)

    def build_sources_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        top.pack_start(self.section_title("ISO Sources"), True, True, 0)
        add = Gtk.Button(label="Add Folder")
        add.connect("clicked", self.on_add_source)
        remove = Gtk.Button(label="Remove")
        remove.connect("clicked", self.on_remove_source)
        top.pack_start(add, False, False, 0)
        top.pack_start(remove, False, False, 0)
        box.pack_start(top, False, False, 0)

        self.source_store = Gtk.ListStore(str)
        self.source_view = Gtk.TreeView(model=self.source_store)
        renderer = Gtk.CellRendererText()
        column = Gtk.TreeViewColumn("Folder", renderer, text=0)
        self.source_view.append_column(column)
        self.source_view.set_size_request(-1, 120)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroller.add(self.source_view)
        box.pack_start(scroller, True, True, 0)
        hint = Gtk.Label(label="Leave empty to use the backend's standard ISO discovery paths.")
        hint.set_halign(Gtk.Align.START)
        hint.get_style_context().add_class("muted")
        box.pack_start(hint, False, False, 0)
        return box

    def build_progress_section(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.status_label = Gtk.Label(label="Ready")
        self.status_label.set_halign(Gtk.Align.START)
        box.pack_start(self.status_label, False, False, 0)
        self.progress = Gtk.ProgressBar()
        box.pack_start(self.progress, False, False, 0)

        self.output = Gtk.TextView()
        self.output.set_editable(False)
        self.output.set_cursor_visible(False)
        self.output.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.output.modify_font(Pango.FontDescription("monospace 10"))
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroller.add(self.output)
        box.pack_start(scroller, True, True, 0)

        self.command_preview = Gtk.Label()
        self.command_preview.set_halign(Gtk.Align.START)
        self.command_preview.set_line_wrap(True)
        self.command_preview.get_style_context().add_class("muted")
        box.pack_start(self.command_preview, False, False, 0)
        return box

    def build_actions(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.run_button = Gtk.Button(label="Run")
        self.run_button.get_style_context().add_class("run-button")
        self.run_button.connect("clicked", self.on_run)
        self.cancel_button = Gtk.Button(label="Cancel")
        self.cancel_button.set_sensitive(False)
        self.cancel_button.connect("clicked", self.on_cancel)
        box.pack_end(self.run_button, False, False, 0)
        box.pack_end(self.cancel_button, False, False, 0)
        return box

    def refresh_devices(self) -> None:
        self.devices = removable_devices()
        self.device_combo.remove_all()
        for device in self.devices:
            self.device_combo.append(device["path"], f"{device['path']}  {device['label']}  {device['size']}")
        if self.devices:
            self.device_combo.set_active(0)
        self.update_device_details()
        self.refresh_command_preview()

    def selected_device(self) -> Optional[Dict[str, str]]:
        active = self.device_combo.get_active_id()
        for device in self.devices:
            if device["path"] == active:
                return device
        return None

    def update_device_details(self) -> None:
        device = self.selected_device()
        if not device:
            self.device_details.set_text("No removable USB devices detected.")
            return
        self.device_details.set_text(
            f"{device['label']}\nCapacity: {device['size']}\nTransport: {device['transport']}"
        )

    def current_action(self) -> str:
        if self.action_create.get_active():
            return "recreate"
        if self.action_update.get_active():
            return "update"
        return "sync-isos"

    def backend_args(self) -> List[str]:
        device = self.selected_device()
        if not device:
            return []
        args = [str(BACKEND), "--no-gui", "--device", device["path"]]
        action = self.current_action()
        args.append(f"--{action}")
        version = self.version_entry.get_text().strip() or "latest"
        args.extend(["--version", version])
        if action == "recreate":
            args.append(f"--{self.partition_combo.get_active_id() or 'mbr'}")
            reserve = int(self.reserve_spin.get_value())
            if reserve > 0:
                args.extend(["--reserve-mib", str(reserve)])
        if action in {"recreate", "sync-isos"}:
            if self.overwrite_switch.get_active():
                args.append("--overwrite")
            for source in self.sources:
                args.extend(["--source", source])
        return args

    def command_for_run(self) -> List[str]:
        args = self.backend_args()
        if not args:
            return []
        if os.geteuid() == 0:
            return ["env", "RTD_VENTOY_CONFIRMED=1", *args]
        if shutil.which("pkexec"):
            return ["pkexec", "env", "RTD_VENTOY_CONFIRMED=1", *args]
        if shutil.which("sudo"):
            return ["sudo", "-E", "env", "RTD_VENTOY_CONFIRMED=1", *args]
        return ["env", "RTD_VENTOY_CONFIRMED=1", *args]

    def refresh_command_preview(self) -> None:
        self.update_device_details()
        args = self.backend_args()
        if args:
            self.command_preview.set_text("Command: " + " ".join(shlex.quote(part) for part in args))
            self.run_button.set_sensitive(self.process is None)
        else:
            self.command_preview.set_text("Select a removable USB device to continue.")
            self.run_button.set_sensitive(False)

    def on_add_source(self, _button: Gtk.Button) -> None:
        dialog = Gtk.FileChooserDialog(
            title="Select ISO Source Folder",
            transient_for=self,
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK)
        try:
            if dialog.run() == Gtk.ResponseType.OK:
                folder = dialog.get_filename()
                if folder and folder not in self.sources:
                    self.sources.append(folder)
                    self.source_store.append([folder])
                    self.refresh_command_preview()
        finally:
            dialog.destroy()

    def on_remove_source(self, _button: Gtk.Button) -> None:
        selection = self.source_view.get_selection()
        model, treeiter = selection.get_selected()
        if treeiter is None:
            return
        value = model[treeiter][0]
        self.sources = [source for source in self.sources if source != value]
        model.remove(treeiter)
        self.refresh_command_preview()

    def append_output(self, text: str) -> None:
        buffer = self.output.get_buffer()
        end = buffer.get_end_iter()
        buffer.insert(end, text)
        mark = buffer.create_mark(None, buffer.get_end_iter(), False)
        self.output.scroll_mark_onscreen(mark)

    def handle_progress(self, line: str) -> bool:
        if not line.startswith("RTD_PROGRESS "):
            return False
        try:
            fields = dict(part.split("=", 1) for part in shlex.split(line)[1:] if "=" in part)
            percent = int(fields.get("percent", "0"))
        except (ValueError, KeyError):
            return True
        percent = max(0, min(100, percent))
        copied = fields.get("copied", "0")
        skipped = fields.get("skipped", "0")
        failed = fields.get("failed", "0")
        total = fields.get("total", "0")
        current = fields.get("current", "")
        self.progress.set_fraction(percent / 100.0)
        self.progress.set_text(f"{percent}%")
        self.status_label.set_text(
            f"ISO copy {percent}%  current: {current}  copied: {copied}  skipped: {skipped}  failed: {failed}  total: {total}"
        )
        return True

    def on_run(self, _button: Gtk.Button) -> None:
        command = self.command_for_run()
        if not command:
            return
        action = self.current_action()
        if action == "recreate":
            if not self.confirm_destructive():
                return
        elif not self.confirm_operation(action):
            return
        self.output.get_buffer().set_text("")
        self.append_output("$ " + " ".join(shlex.quote(part) for part in command) + "\n\n")
        self.progress.set_fraction(0.0)
        self.progress.set_show_text(True)
        self.status_label.set_text("Starting backend...")
        self.run_button.set_sensitive(False)
        self.cancel_button.set_sensitive(True)
        try:
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
        except OSError as error:
            self.process = None
            self.append_output(f"Failed to start backend: {error}\n")
            self.status_label.set_text("Failed to start backend")
            self.run_button.set_sensitive(True)
            self.cancel_button.set_sensitive(False)
            return
        threading.Thread(target=self.read_process_output, daemon=True).start()

    def confirm_destructive(self) -> bool:
        device = self.selected_device()
        device_path = device["path"] if device else "the selected USB device"
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.NONE,
            text="Create USB will erase the selected device.",
        )
        dialog.format_secondary_text(f"Target: {device_path}\n\nType the device path to continue.")
        entry = Gtk.Entry()
        entry.set_placeholder_text(device_path)
        box = dialog.get_content_area()
        box.pack_end(entry, False, False, 0)
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, "Erase and Create", Gtk.ResponseType.OK)
        dialog.show_all()
        response = dialog.run()
        typed = entry.get_text().strip()
        dialog.destroy()
        return response == Gtk.ResponseType.OK and typed == device_path

    def confirm_operation(self, action: str) -> bool:
        device = self.selected_device()
        device_path = device["path"] if device else "the selected USB device"
        if action == "update":
            title = "Update Ventoy on the selected USB device?"
            detail = "Existing ISO files are preserved. Ventoy boot files and RTD branding will be refreshed."
        else:
            title = "Add or refresh ISO files on the selected USB device?"
            detail = "The Ventoy installation is preserved. ISO files may be copied or overwritten depending on your settings."
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text=title,
        )
        dialog.format_secondary_text(f"Target: {device_path}\n\n{detail}")
        response = dialog.run()
        dialog.destroy()
        return response == Gtk.ResponseType.OK

    def read_process_output(self) -> None:
        process = self.process
        if not process or not process.stdout:
            GLib.idle_add(self.on_process_complete, 1)
            return
        for line in process.stdout:
            GLib.idle_add(self.on_process_line, line)
        rc = process.wait()
        GLib.idle_add(self.on_process_complete, rc)

    def on_process_line(self, line: str) -> bool:
        clean = sanitize(line)
        self.handle_progress(clean.strip())
        if not clean.startswith("RTD_PROGRESS "):
            self.append_output(clean)
        return False

    def on_process_complete(self, rc: int) -> bool:
        self.append_output(f"\nBackend exited with status {rc}\n")
        self.status_label.set_text("Complete" if rc == 0 else f"Failed with status {rc}")
        if rc == 0:
            self.progress.set_fraction(1.0)
            self.progress.set_text("100%")
        self.process = None
        self.run_button.set_sensitive(True)
        self.cancel_button.set_sensitive(False)
        self.refresh_command_preview()
        return False

    def on_cancel(self, _button: Gtk.Button) -> None:
        if self.process and self.process.poll() is None:
            self.process.terminate()
            self.status_label.set_text("Cancel requested")

    def on_destroy(self, *_args) -> None:
        if self.process and self.process.poll() is None:
            self.process.terminate()
        Gtk.main_quit()


def main() -> int:
    if not BACKEND.exists():
        print(f"Backend not found: {BACKEND}", file=sys.stderr)
        return 1
    VentoyWindow()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
