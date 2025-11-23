# RTD System Update
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

![RTD Update Screenshot](Media_files/Scr2.png?raw=true "Executing the Script")

This module contains two companion scripts:
- `rtd-update-system`: update OS packages (APT/YUM/Zypper/PKCON), snaps, and Flatpaks from one place
- `rtd-update-self`: refresh the RTD Power Tools installation itself from GitHub and rebuild launchers/themes

Both tools run independently of the rest of the stack and will elevate with `sudo/pkexec` when required.

## rtd-update-system
```bash
# interactive update of all package channels
rtd-update-system

# non-interactive, text-only progress (no dialog/zenity UI)
rtd-update-system --noui

# refresh the updater script from GitHub before running
rtd-update-system update

# verify snaps/flatpak channels are configured
rtd-update-system setup
```
What happens:
- elevates to root if needed, then loads `_rtd_library` helpers
- updates the native package manager, then snaps and Flatpak runtimes if present
- logs to `/var/log/rtd/rtd-update-system.log`

## rtd-update-self
```bash
# update RTD Power Tools, menu launchers, and optional themes
rtd-update-self

# run with no prompts (assumes full update)
rtd-update-self --autoconfirm
```
What happens:
- prompts for which pieces to update (base tools, menu launchers, themes)
- clones fresh content from `https://github.com/<git_profile>/RTD-Setup` into `/opt/rtd`
- backs up the previous install under `/opt/backup` with a timestamped zip
- registers the tools and recreates desktop/menu entries; logs to `/var/log/rtd`
