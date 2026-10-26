"""GTK4 / Libadwaita frontend. All writes go through the shared backend."""
import threading

from studio import ACCENTS, StudioError, catalog, looks, read_json


def create_application(studio):
    try:
        import gi
        gi.require_version('Gtk', '4.0')
        gi.require_version('Adw', '1')
        from gi.repository import Adw, Gio, GLib, Gtk
        if not Gtk.init_check():
            raise StudioError('No graphical display is available. Use --terminal inside your GNOME session.')
    except (ImportError, ValueError) as error:
        raise StudioError('GTK4 and Libadwaita Python bindings are required. Use --terminal, or install your distribution’s GTK4/Libadwaita introspection packages.') from error

    class Thumbnail(Gtk.Picture):
        # SVG intrinsic dimensions must not force one 3840-pixel-wide FlowBox column.
        def do_measure(self, orientation, for_size):
            if orientation == Gtk.Orientation.HORIZONTAL:
                return (240, 280, -1, -1)
            height = round((for_size if for_size > 0 else 280) * 9 / 16)
            return (height, height, -1, -1)

    class Window(Adw.ApplicationWindow):
        def __init__(self, app):
            super().__init__(application=app, title='RTD Theme Studio', default_width=1120, default_height=800)
            self.busy = False
            provider = Gtk.CssProvider()
            provider.load_from_data(b'.studio-card { padding: 14px; }')
            Gtk.StyleContext.add_provider_for_display(self.get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            self.connect('close-request', lambda *_: self.busy)
            root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            self.set_content(root)
            header = Adw.HeaderBar()
            header.set_title_widget(Adw.WindowTitle(title='Theme Studio', subtitle='Your desktop, composed by you'))
            root.append(header)
            self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16,
                                   margin_start=24, margin_end=24, margin_top=12, margin_bottom=16)
            root.append(self.content)
            self.search = Gtk.SearchEntry(placeholder_text='Search looks, themes, and icon families…')
            self.search.connect('search-changed', self.filter_items)
            self.content.append(self.search)
            self.stack = Gtk.Stack(vexpand=True, transition_type=Gtk.StackTransitionType.CROSSFADE)
            switcher = Gtk.StackSwitcher(stack=self.stack, halign=Gtk.Align.CENTER)
            self.content.append(switcher)
            self.content.append(self.stack)
            self.cards = []
            self.look_flow = self.grid('looks', 'Looks')
            for look in looks():
                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8,
                              margin_top=8, margin_bottom=8, margin_start=8, margin_end=8)
                box.add_css_class('card')
                box.add_css_class('studio-card')
                picture = Thumbnail(file=Gio.File.new_for_path(str(studio.wallpaper(look))))
                picture.set_can_shrink(True)
                box.append(picture)
                title = Gtk.Label(label=look['name'], xalign=0)
                title.add_css_class('title-3')
                box.append(title)
                details = Gtk.Label(label=f"{look['accent'].title()} · {look['mode']} · 4K wallpaper", xalign=0)
                details.add_css_class('dim-label')
                box.append(details)
                description = Gtk.Label(label=f"Palette preview · {look['theme_family']} / {look['icon_family']}", xalign=0, wrap=True, max_width_chars=30)
                description.add_css_class('caption')
                box.append(description)
                self.button(box, 'Apply Look', lambda item=look: studio.apply_look(item['id']), suggested=True)
                self.look_flow.append(box)
                self.cards.append((box.get_parent(), (look['name'] + ' ' + look['accent'] + ' ' + look['theme_family'] + ' ' + look['icon_family']).lower()))
            self.family_flows = {}
            for kind, title in [('theme', 'Themes'), ('icons', 'Icons')]:
                flow = self.grid(kind, title)
                self.family_flows[kind] = flow
                for entry in catalog():
                    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10,
                                  margin_start=12, margin_end=12, margin_top=12, margin_bottom=12)
                    box.set_size_request(285, -1)
                    box.add_css_class('card')
                    box.add_css_class('studio-card')
                    name = Gtk.Label(label=entry['name'], xalign=0)
                    name.add_css_class('title-3')
                    box.append(name)
                    box.append(Gtk.Label(label=entry['repository'], xalign=0, selectable=True, wrap=True, max_width_chars=30))
                    label = 'Isolated source build' if entry['method'] == 'installer' else 'Prebuilt asset discovery'
                    box.append(Gtk.Label(label=label, xalign=0))
                    link = Gtk.LinkButton(uri='https://github.com/' + entry['repository'], label='Preview & upstream documentation')
                    link.set_halign(Gtk.Align.START)
                    box.append(link)
                    profiles = Gtk.DropDown.new_from_strings(list(entry.get('profiles', {'default': []})))
                    box.append(profiles)
                    install = Gtk.Button(label='Install family / profile')
                    install.add_css_class('suggested-action')
                    def install_clicked(_button, item=entry, selector=profiles):
                        profile = selector.get_selected_item().get_string()
                        self.perform(lambda: studio.install(item['id'], profile))
                    install.connect('clicked', install_clicked)
                    box.append(install)
                    if entry['kind'] == kind:
                        flow.append(box)
                        self.cards.append((box.get_parent(), (entry['name'] + ' ' + entry['repository']).lower()))
            self.elements()
            self.manage()
            status = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10,
                             margin_start=24, margin_end=24, margin_bottom=16)
            self.spinner = Gtk.Spinner()
            status.append(self.spinner)
            self.message = Gtk.Label(label='Changes stay in your account. A snapshot is saved before every appearance change.',
                                     wrap=True, xalign=0, selectable=True, hexpand=True)
            message_scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER,
                                                min_content_height=48, max_content_height=120,
                                                propagate_natural_height=True, hexpand=True)
            message_scroll.set_child(self.message)
            status.append(message_scroll)
            root.append(status)
            self.refresh()

        def grid(self, name, title):
            scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER)
            flow = Gtk.FlowBox(selection_mode=Gtk.SelectionMode.NONE, homogeneous=True,
                               min_children_per_line=1, max_children_per_line=3,
                               row_spacing=12, column_spacing=12, valign=Gtk.Align.START)
            scroll.set_child(flow)
            self.stack.add_titled(scroll, name, title)
            return flow

        def button(self, parent, label, action, suggested=False):
            button = Gtk.Button(label=label)
            if suggested:
                button.add_css_class('suggested-action')
            button.connect('clicked', lambda *_: self.perform(action))
            parent.append(button)
            return button

        def perform(self, action):
            if self.busy:
                return
            self.busy = True
            self.content.set_sensitive(False)
            self.spinner.start()
            self.message.set_label('Working… downloads and source builds may take several minutes. Please keep this window open.')

            def worker():
                try:
                    message = action()
                except Exception as error:
                    message = f'Could not complete this operation: {error}'
                GLib.idle_add(self.finished, str(message))

            threading.Thread(target=worker, daemon=False).start()

        def finished(self, message):
            self.busy = False
            self.content.set_sensitive(True)
            self.spinner.stop()
            self.message.set_label(message)
            self.refresh()
            return False

        def filter_items(self, *_):
            query = self.search.get_text().strip().lower()
            for child, text in self.cards:
                child.set_visible(query in text)

        def page(self, name, title):
            scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER)
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14, margin_top=12,
                          margin_bottom=16, margin_start=12, margin_end=12)
            scroll.set_child(box)
            self.stack.add_titled(scroll, name, title)
            return box

        def elements(self):
            box = self.page('elements', 'Customize')
            label = Gtk.Label(label='Mix installed variants. Blank selections preserve the current setting.', xalign=0, wrap=True)
            box.append(label)
            self.selectors = {}
            for kind, title in [('gtk', 'Applications / GTK3'), ('shell', 'GNOME Shell'),
                                ('icons', 'Icon pack'), ('cursor', 'Cursor'), ('mode', 'Appearance'), ('accent', 'Accent')]:
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
                row.append(Gtk.Label(label=title, xalign=0, hexpand=True))
                selector = Gtk.DropDown()
                selector.set_size_request(330, -1)
                row.append(selector)
                box.append(row)
                self.selectors[kind] = selector
            wallpaper_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            self.wallpaper = Gtk.Entry(placeholder_text='Optional wallpaper path', hexpand=True)
            wallpaper_row.append(self.wallpaper)
            choose = Gtk.Button(label='Browse…')
            choose.connect('clicked', self.choose_wallpaper)
            wallpaper_row.append(choose)
            box.append(wallpaper_row)
            self.gtk4 = Gtk.CheckButton(label='Also apply this theme’s GTK4 / Libadwaita CSS (backs up existing configuration)')
            box.append(self.gtk4)
            box.append(Gtk.Label(label='GTK4 overrides affect compatible native apps. Sandboxed apps may keep their own appearance. '
                                       'Shell themes need the User Themes extension; native accents require GNOME 47+.',
                                 wrap=True, xalign=0))
            box.append(Gtk.LinkButton(uri='https://extensions.gnome.org/extension/19/user-themes/',
                                      label='User Themes extension: installation and compatibility'))
            apply_button = Gtk.Button(label='Apply selected elements')
            apply_button.add_css_class('suggested-action')
            apply_button.connect('clicked', self.apply_elements)
            box.append(apply_button)
            self.button(box, 'Refresh installed variants', lambda: 'Installed variants refreshed.')

        def choose_wallpaper(self, *_):
            chooser = Gtk.FileChooserNative(title='Choose wallpaper', transient_for=self,
                                            action=Gtk.FileChooserAction.OPEN, accept_label='Select', cancel_label='Cancel')
            file_filter = Gtk.FileFilter()
            file_filter.set_name('Wallpaper images')
            for pattern in ('*.png', '*.jpg', '*.jpeg', '*.svg', '*.webp'):
                file_filter.add_pattern(pattern)
            chooser.add_filter(file_filter)

            def response(dialog, result):
                if result == Gtk.ResponseType.ACCEPT:
                    file = dialog.get_file()
                    if file and file.get_path():
                        self.wallpaper.set_text(file.get_path())
                dialog.destroy()
            chooser.connect('response', response)
            chooser.show()

        def apply_elements(self, *_):
            values = {}
            for kind, selector in self.selectors.items():
                selected = selector.get_selected_item()
                if selected and selected.get_string() != 'Keep current':
                    value = selected.get_string()
                    values[kind] = '' if kind == 'shell' and value == 'GNOME default' else value
            if self.wallpaper.get_text().strip():
                values['wallpaper'] = self.wallpaper.get_text().strip()
            values['gtk4'] = self.gtk4.get_active()
            self.perform(lambda: studio.apply(**values))

        def manage(self):
            box = self.page('manage', 'Library & Recovery')
            self.summary = Gtk.Label(xalign=0, wrap=True)
            box.append(self.summary)
            self.managed = Gtk.DropDown()
            box.append(self.managed)
            remove = Gtk.Button(label='Remove selected managed family')
            remove.connect('clicked', self.remove_selected)
            box.append(remove)
            self.saved = Gtk.DropDown()
            box.append(self.saved)
            apply_saved = Gtk.Button(label='Apply saved look (installs missing managed families)')
            apply_saved.connect('clicked', self.apply_saved)
            box.append(apply_saved)
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            self.look_name = Gtk.Entry(placeholder_text='my-desktop-look', hexpand=True)
            row.append(self.look_name)
            save = Gtk.Button(label='Save current look')
            save.connect('clicked', lambda *_: self.save_current())
            row.append(save)
            box.append(row)
            self.button(box, 'Undo last appearance change', lambda: studio.recover(True))
            self.button(box, 'Recover interrupted change', studio.recover)
            self.button(box, 'Reset to Ubuntu defaults (Yaru)', lambda: studio.reset(True))
            self.button(box, 'Reset to distribution defaults', studio.reset)
            self.button(box, 'Add Theme Studio to app grid', studio.add_launcher)
            box.append(Gtk.Label(label='Only assets installed by Theme Studio can be removed. Active themes are protected. '
                                       'Reset restores appearance settings and your original GTK4 configuration; it does not remove installed assets.',
                                 wrap=True, xalign=0))

        def save_current(self):
            name = self.look_name.get_text().strip()
            self.perform(lambda: studio.save_look(name))

        def remove_selected(self, *_):
            item = self.managed.get_selected_item()
            if item:
                family = item.get_string()
                self.perform(lambda: studio.uninstall(family))

        def apply_saved(self, *_):
            item = self.saved.get_selected_item()
            if item:
                name = item.get_string()
                self.perform(lambda: studio.apply_look(name))

        def refresh(self):
            try:
                inventory = studio.installed()
                for kind, selector in self.selectors.items():
                    current = selector.get_selected_item()
                    current = current.get_string() if current else 'Keep current'
                    options = sorted(inventory[kind]) if kind in inventory else (['light', 'dark'] if kind == 'mode' else list(ACCENTS))
                    if kind == 'shell':
                        options.insert(0, 'GNOME default')
                    options.insert(0, 'Keep current')
                    selector.set_model(Gtk.StringList.new(options))
                    selector.set_selected(options.index(current) if current in options else 0)
                self.managed.set_model(Gtk.StringList.new(sorted(studio.registry())))
                self.saved.set_model(Gtk.StringList.new(sorted(read_json(studio.assets / 'looks.json', {}))))
                self.summary.set_label(f"Installed: {len(inventory['gtk'])} GTK variants · {len(inventory['shell'])} Shell variants · "
                                       f"{len(inventory['icons'])} icon variants · {len(inventory['cursor'])} cursors")
            except Exception as error:
                self.message.set_label(str(error))

    class Application(Adw.Application):
        def __init__(self):
            super().__init__(application_id='org.rtd.ThemeStudio', flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

        def do_activate(self):
            window = self.get_active_window()
            if not window:
                window = Window(self)
            window.present()

    return Application()


def launch(studio):
    create_application(studio).run([])
