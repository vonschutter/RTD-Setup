#!/usr/bin/env python3
"""Real GTK smoke test; requires a display, uses a temporary home and memory settings."""
import os
from pathlib import Path
import sys
import tempfile
import time
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ['GSETTINGS_BACKEND'] = 'memory'
from studio import Studio
from studio_gtk import create_application
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gtk

with tempfile.TemporaryDirectory(prefix='rtd-studio-gui-') as home:
    for key, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_STATE_HOME', 'state')]:
        os.environ[key] = str(Path(home) / suffix)
    app = create_application(Studio(home))
    app.register(None)
    app.activate()
    context = GLib.MainContext.default()
    deadline = time.monotonic() + 1
    while time.monotonic() < deadline:
        while context.pending():
            context.iteration(False)
        time.sleep(.01)
    window = app.get_active_window()
    assert window is not None, 'Window failed to open'
    assert len(window.cards) == 63, len(window.cards)
    _, first = window.cards[0][0].compute_bounds(window.look_flow)
    _, second = window.cards[1][0].compute_bounds(window.look_flow)
    assert first.get_y() == second.get_y() and second.get_x() > first.get_x(), 'Look gallery failed to form columns'
    if os.environ.get('RTD_STUDIO_SMOKE_SCREENSHOT'):
        snapshot = Gtk.Snapshot()
        Gtk.WidgetPaintable.new(window).snapshot(snapshot, window.get_width(), window.get_height())
        texture = window.get_renderer().render_texture(snapshot.to_node(), None)
        texture.save_to_png(os.environ['RTD_STUDIO_SMOKE_SCREENSHOT'])
    for name in ('looks', 'theme', 'icons', 'elements', 'manage'):
        window.stack.set_visible_child_name(name)
        while context.pending():
            context.iteration(False)
    window.search.set_text('orchis')
    window.filter_items()
    assert sum(child.get_visible() for child, _ in window.cards) >= 1
    assert sum(child.get_visible() for child, _ in window.cards) < 63
    window.perform(lambda: 'Smoke action completed')
    deadline = time.monotonic() + 5
    while window.busy and time.monotonic() < deadline:
        context.iteration(True)
    assert not window.busy
    assert window.message.get_label() == 'Smoke action completed'
    window.destroy()
    app.quit()
    print('GTK smoke passed: all five pages, 63 cards, search, asynchronous action, refresh, close.')
