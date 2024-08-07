GNOME Shell Extension Installer
===============================
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

This is a script used to install and search for extensions from [extensions.gnome.org](https://extensions.gnome.org/).

ORIGIN: [https://github.com/brunelli/gnome-shell-extension-installer]()


## How to use the script:

```
Usage: rtd-gnome-shell-extension-installer EXTENSION_ID [EXTENSION_ID...] [GNOME_VERSION] [OPTIONS]

Options:
  -s or --search [STRING] Interactive search.
  --yes                   Skip all prompts.
  --no-install            Saves the extension(s) in the current directory.
  --update                Check for new versions.
  --restart-shell         Restart GNOME Shell after the extensions are installed.
  -h or --help            Print this message.

Usage examples:
  gnome-shell-extension-installer 307               # Install "Dash to Dock"
  gnome-shell-extension-installer 307 3.8           # Install for Shell 3.8
  gnome-shell-extension-installer 53 --no-install   # Download "Pomodoro"
  gnome-shell-extension-installer -s "User Themes"  # Search "User Themes"
```

By default extensions are installed in `$HOME/.local/share/gnome-shell/extensions/`,
except if the script is run with super user permission
(then, it will be installed in `/usr/share/gnome-shell/extensions/`).
