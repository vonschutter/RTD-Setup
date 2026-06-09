#!/usr/bin/env python3

#
#::                          RTD macOS KVM GTK Frontend
#::                     G R A P H I C A L    F R O N T E N D
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#:: Module:     macos-kvm.mod
#:: Script:     macos-kvm-gtk.py
#:: Author(s):  RTD Team (vonschutter)
#:: Version:    1.0
#::
#:: Purpose:    Provides the GTK window for the RTD macOS KVM GUI launcher. The
#::             frontend builds commands for the rtd-macos-kvm backend, displays
#::             the selected workflow, streams progress output, and exposes common
#::             actions for host checks, installer preparation, VM definition, and
#::             virt-manager launch.
#::
#:: Usage:      rtd-macos-kvm-gui
#::
#:: Requires:   python3, python3-gi, GTK 3 introspection bindings, and the sibling
#::             rtd-macos-kvm backend script.
#::
#:: Runtime:    This file is intentionally not named rtd-* and is not intended to
#::             be installed as a direct command. Use rtd-macos-kvm-gui so RTD can
#::             validate the graphical session and install Python GTK dependencies
#::             before this frontend is executed.
#::
#:: Notes:      Administrative backend actions are run through pkexec when the
#::             frontend is not already running as root. Progress output is
#::             sanitized before display so terminal color/control sequences do
#::             not leak into the GTK TextView.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

try:
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GdkPixbuf", "2.0")
    from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango
except (ImportError, ValueError) as error:
    raise SystemExit(
        "RTD macOS KVM GUI requires GTK 3 Python bindings (python3-gi): "
        f"{error}"
    )


APP_DIR = Path(__file__).resolve().parent
BACKEND = APP_DIR / "rtd-macos-kvm"
BANNER = APP_DIR / "Media_files" / "macos-kvm-gui-banner.png"
DEFAULT_BOOT_DIR = "/var/lib/libvirt/boot"
DEFAULT_IMAGE_DIR = "/var/lib/libvirt/images"
TERMINAL_ESCAPE_RE = re.compile(
    r"\x1b(?:"
    r"\[[0-?]*[A-Za-z@^_`{}~]|"
    r"\][^\x07]*(?:\x07|\x1b\\)|"
    r"[()][A-Za-z0-9]|"
    r"[@-Z\\-_]"
    r")"
)
BROKEN_COLOR_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]{1,16}(?=\s|$)")

VERSIONS = (
    ("sonoma", "Sonoma 14 (recommended modern)"),
    ("sequoia", "Sequoia 15"),
    ("ventura", "Ventura 13"),
    ("monterey", "Monterey 12"),
    ("big-sur", "Big Sur 11"),
    ("catalina", "Catalina 10.15 (legacy default)"),
    ("mojave", "Mojave 10.14"),
    ("high-sierra", "High Sierra 10.13"),
    ("tahoe", "Tahoe 26"),
)

COMMANDS = (
    ("prepare", "Prepare complete VM"),
    ("doctor", "Check host readiness"),
    ("fetch-installer", "Fetch installer media"),
    ("stage-assets", "Stage boot assets"),
    ("define-vm", "Define VM from staged assets"),
)


def combo(items, active=0):
    widget = Gtk.ComboBoxText()
    for value, label in items:
        widget.append(value, label)
    widget.set_active(active)
    return widget


def entry(text=""):
    widget = Gtk.Entry()
    widget.set_text(text)
    return widget


def spin(value, lower, upper, step):
    adjustment = Gtk.Adjustment(value=value, lower=lower, upper=upper, step_increment=step)
    widget = Gtk.SpinButton(adjustment=adjustment, climb_rate=1, digits=0)
    widget.set_numeric(True)
    return widget


def switch(active=False):
    widget = Gtk.Switch()
    widget.set_active(active)
    widget.set_halign(Gtk.Align.START)
    return widget


def sanitize_terminal_output(text):
    text = TERMINAL_ESCAPE_RE.sub("", text)
    return BROKEN_COLOR_ESCAPE_RE.sub("", text)


class MacOSKvmWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="RTD macOS KVM")
        self.set_default_size(1080, 760)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("destroy", Gtk.main_quit)
        self.process = None

        self.build_css()
        self.add(self.build_window())
        self.refresh_command()
        self.show_all()

    def build_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(
            b"""
            .hero-title { color: #ffffff; font-size: 30px; font-weight: 700; }
            .hero-copy { color: #dbeafe; font-size: 13px; }
            .section-title { font-size: 19px; font-weight: 700; }
            .muted { color: #64748b; }
            .status-pill { border-radius: 4px; padding: 5px 9px; background: #e2e8f0; }
            textview { font-family: monospace; font-size: 10pt; }
            """
        )
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def build_window(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.pack_start(self.build_banner(), False, False, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=18)
        body.set_border_width(18)
        outer.pack_start(body, True, True, 0)

        controls = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        controls.set_size_request(410, -1)
        body.pack_start(controls, False, False, 0)
        controls.pack_start(self.build_workflow_card(), False, False, 0)
        controls.pack_start(self.build_vm_card(), False, False, 0)
        controls.pack_start(self.build_advanced_card(), False, False, 0)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        body.pack_start(right, True, True, 0)
        right.pack_start(self.build_review_card(), False, False, 0)
        right.pack_start(self.build_output_card(), True, True, 0)
        right.pack_start(self.build_actions(), False, False, 0)
        return outer

    def build_banner(self):
        overlay = Gtk.Overlay()
        overlay.set_size_request(-1, 220)
        if BANNER.is_file():
            pixels = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(BANNER), 1080, 220, False)
            overlay.add(Gtk.Image.new_from_pixbuf(pixels))
        else:
            fallback = Gtk.EventBox()
            fallback.get_style_context().add_class("view")
            overlay.add(fallback)

        copy = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        copy.set_halign(Gtk.Align.START)
        copy.set_valign(Gtk.Align.CENTER)
        copy.set_margin_start(36)
        title = Gtk.Label(label="RTD macOS KVM")
        title.get_style_context().add_class("hero-title")
        title.set_halign(Gtk.Align.START)
        subtitle = Gtk.Label(
            label="Prepare recovery media, OpenCore boot assets, libvirt storage, and a ready-to-install macOS VM."
        )
        subtitle.get_style_context().add_class("hero-copy")
        subtitle.set_halign(Gtk.Align.START)
        subtitle.set_line_wrap(True)
        subtitle.set_max_width_chars(70)
        copy.pack_start(title, False, False, 0)
        copy.pack_start(subtitle, False, False, 0)
        overlay.add_overlay(copy)
        return overlay

    def card(self, title):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        title_label = Gtk.Label(label=title)
        title_label.get_style_context().add_class("section-title")
        title_label.set_halign(Gtk.Align.START)
        box.pack_start(title_label, False, False, 0)
        return box

    def add_row(self, grid, row, label, control):
        text = Gtk.Label(label=label)
        text.set_halign(Gtk.Align.START)
        text.set_valign(Gtk.Align.CENTER)
        grid.attach(text, 0, row, 1, 1)
        control.set_hexpand(True)
        grid.attach(control, 1, row, 1, 1)

    def build_workflow_card(self):
        card = self.card("Workflow")
        grid = Gtk.Grid(column_spacing=14, row_spacing=10)
        card.pack_start(grid, False, False, 0)
        self.command = combo(COMMANDS)
        self.version = combo(VERSIONS)
        self.command.connect("changed", self.on_command_changed)
        self.version.connect("changed", self.refresh_command)
        self.add_row(grid, 0, "Action", self.command)
        self.add_row(grid, 1, "macOS version", self.version)

        self.note = Gtk.Label()
        self.note.set_halign(Gtk.Align.START)
        self.note.set_line_wrap(True)
        self.note.get_style_context().add_class("muted")
        card.pack_start(self.note, False, False, 0)
        return card

    def build_vm_card(self):
        card = self.card("VM Settings")
        grid = Gtk.Grid(column_spacing=14, row_spacing=10)
        card.pack_start(grid, False, False, 0)
        self.vm_name = entry("RTD-macOS-Sonoma")
        self.memory = spin(8192, 2048, 65536, 512)
        self.cpus = spin(4, 1, 32, 1)
        self.disk_size = entry("128G")
        self.disk_name = entry("")
        self.add_row(grid, 0, "VM name", self.vm_name)
        self.add_row(grid, 1, "Memory MiB", self.memory)
        self.add_row(grid, 2, "vCPUs", self.cpus)
        self.add_row(grid, 3, "Disk size", self.disk_size)
        self.add_row(grid, 4, "Disk filename", self.disk_name)
        for widget in (self.vm_name, self.disk_size, self.disk_name):
            widget.connect("changed", self.refresh_command)
        for widget in (self.memory, self.cpus):
            widget.connect("value-changed", self.refresh_command)
        return card

    def build_advanced_card(self):
        card = self.card("Advanced")
        grid = Gtk.Grid(column_spacing=14, row_spacing=10)
        card.pack_start(grid, False, False, 0)
        self.boot_dir = entry(DEFAULT_BOOT_DIR)
        self.image_dir = entry(DEFAULT_IMAGE_DIR)
        self.bootloader = combo((("auto", "Auto"), ("opencore-kvm", "OpenCore"), ("clover", "Clover legacy")))
        self.force = switch(False)
        self.keep_work = switch(False)
        self.no_define = switch(False)
        self.add_row(grid, 0, "Boot cache", self.boot_dir)
        self.add_row(grid, 1, "Image dir", self.image_dir)
        self.add_row(grid, 2, "Bootloader", self.bootloader)
        self.add_row(grid, 3, "Force refresh", self.force)
        self.add_row(grid, 4, "Keep work files", self.keep_work)
        self.add_row(grid, 5, "Prepare only", self.no_define)
        for widget in (self.boot_dir, self.image_dir):
            widget.connect("changed", self.refresh_command)
        self.bootloader.connect("changed", self.refresh_command)
        for widget in (self.force, self.keep_work, self.no_define):
            widget.connect("notify::active", self.refresh_command)
        return card

    def build_review_card(self):
        card = self.card("Command Review")
        self.command_preview = Gtk.Label()
        self.command_preview.set_selectable(True)
        self.command_preview.set_xalign(0)
        self.command_preview.set_line_wrap(True)
        self.command_preview.set_line_wrap_mode(Pango.WrapMode.CHAR)
        card.pack_start(self.command_preview, False, False, 0)
        return card

    def build_output_card(self):
        card = self.card("Progress")
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        self.output = Gtk.TextView()
        self.output.set_editable(False)
        self.output.set_cursor_visible(False)
        self.output.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.buffer = self.output.get_buffer()
        scroller.add(self.output)
        card.pack_start(scroller, True, True, 0)
        self.status = Gtk.Label(label="Ready.")
        self.status.set_halign(Gtk.Align.START)
        self.status.get_style_context().add_class("status-pill")
        card.pack_start(self.status, False, False, 0)
        return card

    def build_actions(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.doctor_button = Gtk.Button(label="Run Host Check")
        self.run_button = Gtk.Button(label="Run Selected Action")
        self.stop_button = Gtk.Button(label="Stop")
        self.virt_manager_button = Gtk.Button(label="Open virt-manager")
        self.stop_button.set_sensitive(False)
        self.doctor_button.connect("clicked", lambda _button: self.run_command(["doctor"]))
        self.run_button.connect("clicked", lambda _button: self.run_command(self.build_args()))
        self.stop_button.connect("clicked", self.stop_process)
        self.virt_manager_button.connect("clicked", self.open_virt_manager)
        box.pack_start(self.doctor_button, False, False, 0)
        box.pack_start(self.run_button, False, False, 0)
        box.pack_start(self.stop_button, False, False, 0)
        box.pack_end(self.virt_manager_button, False, False, 0)
        return box

    def on_command_changed(self, _widget):
        self.refresh_command()
        self.set_control_sensitivity()

    def set_control_sensitivity(self):
        command = self.command.get_active_id() or "prepare"
        uses_vm = command in {"prepare", "define-vm"}
        uses_version = command in {"prepare", "fetch-installer"}
        uses_images = command in {"prepare", "define-vm"}
        self.version.set_sensitive(uses_version)
        for widget in (self.vm_name, self.memory, self.cpus, self.disk_size, self.disk_name):
            widget.set_sensitive(uses_vm)
        self.disk_size.set_sensitive(command == "prepare")
        self.image_dir.set_sensitive(uses_images)
        self.no_define.set_sensitive(command == "prepare")
        self.keep_work.set_sensitive(command in {"prepare", "fetch-installer"})

    def build_args(self):
        command = self.command.get_active_id() or "prepare"
        args = [command]
        if command in {"prepare", "fetch-installer"}:
            args += ["--version", self.version.get_active_id() or "sonoma"]
        if command in {"prepare", "stage-assets"}:
            args += ["--bootloader", self.bootloader.get_active_id() or "auto"]
        if command in {"prepare", "fetch-installer", "stage-assets", "define-vm"}:
            args += ["--dir", self.boot_dir.get_text().strip() or DEFAULT_BOOT_DIR]
        if command in {"prepare", "define-vm"}:
            vm_name = self.vm_name.get_text().strip()
            if vm_name:
                args += ["--vm-name", vm_name]
            args += ["--memory", str(self.memory.get_value_as_int())]
            args += ["--cpus", str(self.cpus.get_value_as_int())]
            args += ["--image-dir", self.image_dir.get_text().strip() or DEFAULT_IMAGE_DIR]
            disk_name = self.disk_name.get_text().strip()
            if disk_name:
                args += ["--disk-name", disk_name]
        if command == "prepare":
            args += ["--disk-size", self.disk_size.get_text().strip() or "128G"]
            if self.no_define.get_active():
                args.append("--no-define")
        if self.force.get_active() and command in {"prepare", "fetch-installer", "stage-assets", "define-vm"}:
            args.append("--force")
        if self.keep_work.get_active() and command in {"prepare", "fetch-installer"}:
            args.append("--keep-work")
        return args

    def display_command(self, args):
        command = [str(BACKEND)] + args
        if args and args[0] != "doctor" and os.geteuid() != 0:
            command = ["pkexec"] + command
        return " ".join(shlex.quote(part) for part in command)

    def refresh_command(self, *_args):
        args = self.build_args()
        self.command_preview.set_text(self.display_command(args))
        command = args[0] if args else "prepare"
        notes = {
            "prepare": "Complete workflow: dependencies, boot assets, installer media, disk image, and libvirt VM definition.",
            "doctor": "Checks host readiness without changing the system.",
            "fetch-installer": "Downloads and converts Apple recovery media into the boot cache.",
            "stage-assets": "Stages OpenCore/Clover boot media and OVMF firmware.",
            "define-vm": "Defines a libvirt VM from assets that already exist.",
        }
        self.note.set_text(notes.get(command, ""))

    def append_output(self, text):
        end = self.buffer.get_end_iter()
        self.buffer.insert(end, sanitize_terminal_output(text))
        mark = self.buffer.create_mark(None, self.buffer.get_end_iter(), False)
        self.output.scroll_to_mark(mark, 0.0, True, 0.0, 1.0)

    def clear_output(self):
        self.buffer.set_text("")

    def run_command(self, args):
        if self.process is not None:
            self.message("A task is already running", "Stop the current task before starting another one.", Gtk.MessageType.WARNING)
            return
        command = [str(BACKEND)] + args
        if args and args[0] != "doctor" and os.geteuid() != 0:
            if not shutil.which("pkexec"):
                self.message("pkexec is required", "Install or run with pkexec available so the GUI can perform admin actions.", Gtk.MessageType.ERROR)
                return
            command = ["pkexec"] + command
        self.clear_output()
        self.append_output("$ " + " ".join(shlex.quote(part) for part in command) + "\n\n")
        self.status.set_text("Running...")
        self.run_button.set_sensitive(False)
        self.doctor_button.set_sensitive(False)
        self.stop_button.set_sensitive(True)
        try:
            env = os.environ.copy()
            env["NO_COLOR"] = "1"
            env["CLICOLOR"] = "0"
            env["CLICOLOR_FORCE"] = "0"
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1,
                env=env,
            )
        except OSError as error:
            self.process = None
            self.status.set_text("Failed to start.")
            self.run_button.set_sensitive(True)
            self.doctor_button.set_sensitive(True)
            self.stop_button.set_sensitive(False)
            self.message("Could not start command", str(error), Gtk.MessageType.ERROR)
            return
        GLib.io_add_watch(self.process.stdout, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, self.read_output)
        GLib.timeout_add(300, self.check_process)

    def read_output(self, stream, condition):
        if condition & GLib.IO_IN:
            line = stream.readline()
            if line:
                self.append_output(line)
                return True
        if condition & (GLib.IO_HUP | GLib.IO_ERR):
            remaining = stream.read()
            if remaining:
                self.append_output(remaining)
            return False
        return True

    def check_process(self):
        if self.process is None:
            return False
        rc = self.process.poll()
        if rc is None:
            return True
        self.status.set_text("Completed successfully." if rc == 0 else f"Finished with exit code {rc}.")
        self.process = None
        self.run_button.set_sensitive(True)
        self.doctor_button.set_sensitive(True)
        self.stop_button.set_sensitive(False)
        return False

    def stop_process(self, _button):
        if self.process is not None:
            self.process.terminate()
            self.append_output("\nTask termination requested.\n")

    def open_virt_manager(self, _button):
        if not shutil.which("virt-manager"):
            self.message("virt-manager not found", "Install virt-manager or open the VM through another libvirt client.", Gtk.MessageType.WARNING)
            return
        subprocess.Popen(["virt-manager"])

    def message(self, title, detail, message_type):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=Gtk.DialogFlags.MODAL,
            message_type=message_type,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(detail)
        dialog.run()
        dialog.destroy()


def main():
    if not BACKEND.is_file():
        raise SystemExit(f"Backend script not found: {BACKEND}")
    window = MacOSKvmWindow()
    window.set_control_sensitivity()
    Gtk.main()


if __name__ == "__main__":
    main()
