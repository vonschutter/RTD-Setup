#!/usr/bin/env python3

#
#::                          RTD Bootstrap Progress GTK
#::                     G R A P H I C A L    F R O N T E N D
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::// RTD Bootstrap Progress //::::::::::::::::::::::::::::::::::// Linux //::::::::
#:: Module:     core
#:: Script:     rtd-bootstrap-progress-gtk.py
#:: Author(s):  RTD Team (vonschutter)
#:: Version:    1.0
#::
#:: Purpose:    Provides an optional GTK progress window for rtd-me.sh.cmd. The
#::             wrapper runs the existing bootstrap script as a child process,
#::             streams its output, and checks off high-level setup steps without
#::             replacing the terminal bootstrap logic.
#::
#:: Usage:      RTD_BOOTSTRAP_NO_GUI=1 python3 rtd-bootstrap-progress-gtk.py \
#::             /path/to/rtd-me.sh.cmd [bootstrap arguments]
#::
#:: Requires:   python3, python3-gi, GTK 3 introspection bindings, and a readable
#::             local rtd-me.sh.cmd script path.
#::
#:: Runtime:    Intended to be fetched and piped directly into python3 by the
#::             bootstrap script. If this frontend cannot start, rtd-me.sh.cmd
#::             falls back to its existing terminal workflow.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.request

try:
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GdkPixbuf", "2.0")
    from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango
except (ImportError, ValueError) as error:
    raise SystemExit(f"RTD bootstrap GUI requires GTK 3 Python bindings: {error}")


BANNER_URL = os.environ.get("RTD_BOOTSTRAP_BANNER_URL", "")
STARTED_FILE = os.environ.get("RTD_BOOTSTRAP_GUI_STARTED_FILE", "")
WINDOW_TITLE = os.environ.get("RTD_BOOTSTRAP_WINDOW_TITLE", "RTD System Setup")
HERO_TITLE = os.environ.get("RTD_BOOTSTRAP_HERO_TITLE", WINDOW_TITLE)
HERO_SUBTITLE = os.environ.get(
    "RTD_BOOTSTRAP_HERO_SUBTITLE",
    "Preparing tools, configuration, and desktop integration.",
)
MAXIMIZED = os.environ.get("RTD_BOOTSTRAP_MAXIMIZED", "").lower() in {"1", "true", "yes"}
TERMINAL_ESCAPE_RE = re.compile(
    r"\x1b(?:"
    r"\[[0-?]*[A-Za-z@^_`{}~]|"
    r"\][^\x07]*(?:\x07|\x1b\\)|"
    r"[()][A-Za-z0-9]|"
    r"[@-Z\\-_]"
    r")"
)
BROKEN_COLOR_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]{1,16}(?=\s|$)")

STEPS = (
    ("start", "Bootstrap started"),
    ("admin", "Administrative access ready"),
    ("deps", "Required tools checked"),
    ("clone", "Repository downloaded"),
    ("backup", "Previous install backed up"),
    ("install", "Repository installed"),
    ("register", "RTD tools registered"),
    ("stage2", "Linux configuration started"),
    ("complete", "Bootstrap completed"),
)

PATTERNS = (
    ("admin", ("administrative access", "sudo")),
    ("deps", ("RTD_STEP:deps:done", "required software", "git", "zip")),
    ("clone", ("RTD_STEP:clone:done", "Instructions successfully retrieved", "successfully retrieved")),
    ("backup", ("RTD_STEP:backup:done", ".bakup", "backup")),
    ("install", ("RTD_STEP:install:done", "RTD_STEP:repo-installed:done")),
    ("register", ("RTD_STEP:register:done", "register_all_tools")),
    ("stage2", ("RTD_STEP:stage2:start", "rtd-oem-linux-config.sh")),
    ("complete", ("RTD_STEP:complete:done", "Bootstrap completed")),
)


def sanitize_terminal_output(text):
    text = TERMINAL_ESCAPE_RE.sub("", text)
    return BROKEN_COLOR_ESCAPE_RE.sub("", text)


class BootstrapProgressWindow(Gtk.Window):
    def __init__(self, script, args):
        super().__init__(title=WINDOW_TITLE)
        self.script = script
        self.args = args
        self.process = None
        self.exit_code = 1
        self.step_rows = {}
        self.set_default_size(1080, 760)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("destroy", self.on_destroy)

        self.build_css()
        self.add(self.build_window())
        self.show_all()
        if MAXIMIZED:
            self.maximize()
        self.mark_step("start")
        GLib.idle_add(self.start_process)

    def build_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(
            b"""
            .hero-title { color: #ffffff; font-size: 30px; font-weight: 700; }
            .hero-copy { color: #dbeafe; font-size: 13px; }
            .section-title { font-size: 19px; font-weight: 700; }
            .muted { color: #64748b; }
            .status-pill { border-radius: 4px; padding: 5px 9px; background: #e2e8f0; }
            .step-done { color: #22c55e; font-weight: 700; }
            .step-pending { color: #94a3b8; }
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

        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        left.set_size_request(330, -1)
        body.pack_start(left, False, False, 0)
        left.pack_start(self.build_steps(), False, False, 0)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        body.pack_start(right, True, True, 0)
        right.pack_start(self.build_output(), True, True, 0)
        right.pack_start(self.build_actions(), False, False, 0)
        return outer

    def build_banner(self):
        overlay = Gtk.Overlay()
        overlay.set_size_request(-1, 220)
        pixbuf = self.load_banner()
        if pixbuf is not None:
            overlay.add(Gtk.Image.new_from_pixbuf(pixbuf))
        else:
            fallback = Gtk.EventBox()
            fallback.get_style_context().add_class("view")
            overlay.add(fallback)

        copy = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        copy.set_halign(Gtk.Align.START)
        copy.set_valign(Gtk.Align.CENTER)
        copy.set_margin_start(36)
        title = Gtk.Label(label=HERO_TITLE)
        title.get_style_context().add_class("hero-title")
        title.set_halign(Gtk.Align.START)
        subtitle = Gtk.Label(label=HERO_SUBTITLE)
        subtitle.get_style_context().add_class("hero-copy")
        subtitle.set_halign(Gtk.Align.START)
        copy.pack_start(title, False, False, 0)
        copy.pack_start(subtitle, False, False, 0)
        overlay.add_overlay(copy)
        return overlay

    def load_banner(self):
        if not BANNER_URL:
            return None
        try:
            with urllib.request.urlopen(BANNER_URL, timeout=8) as response:
                data = response.read()
            loader = GdkPixbuf.PixbufLoader.new()
            loader.write(data)
            loader.close()
            return loader.get_pixbuf().scale_simple(1080, 220, GdkPixbuf.InterpType.BILINEAR)
        except Exception:
            return None

    def build_steps(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        title = Gtk.Label(label="Setup Progress")
        title.get_style_context().add_class("section-title")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)
        for key, label in STEPS:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            icon = Gtk.Label(label="○")
            icon.get_style_context().add_class("step-pending")
            text = Gtk.Label(label=label)
            text.set_halign(Gtk.Align.START)
            text.set_line_wrap(True)
            text.get_style_context().add_class("step-pending")
            row.pack_start(icon, False, False, 0)
            row.pack_start(text, True, True, 0)
            box.pack_start(row, False, False, 0)
            self.step_rows[key] = (icon, text)
        self.status = Gtk.Label(label="Starting...")
        self.status.set_halign(Gtk.Align.START)
        self.status.get_style_context().add_class("status-pill")
        box.pack_start(self.status, False, False, 14)
        return box

    def build_output(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        title = Gtk.Label(label="Live Output")
        title.get_style_context().add_class("section-title")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        self.output = Gtk.TextView()
        self.output.set_editable(False)
        self.output.set_cursor_visible(False)
        self.output.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.output.get_buffer().set_text("")
        scroller.add(self.output)
        box.pack_start(scroller, True, True, 0)
        return box

    def build_actions(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.close_button = Gtk.Button(label="Close")
        self.close_button.set_sensitive(False)
        self.close_button.connect("clicked", lambda _button: Gtk.main_quit())
        self.cancel_button = Gtk.Button(label="Cancel")
        self.cancel_button.connect("clicked", self.cancel_process)
        box.pack_end(self.close_button, False, False, 0)
        box.pack_end(self.cancel_button, False, False, 0)
        return box

    def mark_step(self, key):
        row = self.step_rows.get(key)
        if row is None:
            return
        icon, text = row
        icon.set_text("✓")
        for widget in row:
            context = widget.get_style_context()
            context.remove_class("step-pending")
            context.add_class("step-done")

    def append_output(self, text):
        text = sanitize_terminal_output(text)
        for key, needles in PATTERNS:
            if any(needle in text for needle in needles):
                self.mark_step(key)
        buffer = self.output.get_buffer()
        end = buffer.get_end_iter()
        buffer.insert(end, text)
        mark = buffer.create_mark(None, buffer.get_end_iter(), False)
        self.output.scroll_to_mark(mark, 0.0, True, 0.0, 1.0)

    def start_process(self):
        command = ["bash", self.script] + self.args
        self.append_output("$ " + " ".join(command) + "\n\n")
        env = os.environ.copy()
        env["RTD_BOOTSTRAP_NO_GUI"] = "1"
        env["NO_COLOR"] = "1"
        env["CLICOLOR"] = "0"
        env["CLICOLOR_FORCE"] = "0"
        try:
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1,
                env=env,
            )
        except OSError as error:
            self.status.set_text("Failed to start bootstrap.")
            self.append_output(f"Error: {error}\n")
            self.finish(False)
            return False
        self.status.set_text("Running...")
        GLib.io_add_watch(self.process.stdout, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, self.read_output)
        GLib.timeout_add(300, self.check_process)
        return False

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
        self.exit_code = rc
        self.finish(rc == 0)
        return False

    def finish(self, success):
        if success:
            self.mark_step("complete")
            self.status.set_text("Completed successfully.")
        else:
            self.status.set_text("Finished with errors.")
        self.process = None
        self.cancel_button.set_sensitive(False)
        self.close_button.set_sensitive(True)

    def cancel_process(self, _button):
        if self.process is not None:
            self.process.terminate()
            self.append_output("\nCancellation requested.\n")

    def on_destroy(self, _widget):
        if self.process is not None and self.process.poll() is None:
            self.exit_code = 130
            self.process.terminate()
        Gtk.main_quit()


def main():
    if len(sys.argv) < 2:
        raise SystemExit("Usage: rtd-bootstrap-progress-gtk.py /path/to/rtd-me.sh.cmd [args...]")
    script = Path(sys.argv[1])
    if not script.is_file():
        raise SystemExit(f"Bootstrap script is not readable: {script}")
    window = BootstrapProgressWindow(str(script), sys.argv[2:])
    if STARTED_FILE:
        try:
            Path(STARTED_FILE).write_text("started\n")
        except OSError:
            pass
    window.set_keep_above(False)
    Gtk.main()
    raise SystemExit(window.exit_code)


if __name__ == "__main__":
    main()
