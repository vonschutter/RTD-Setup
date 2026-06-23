# RTD System Update
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

![RTD Update Screenshot](Media_files/Screenshot2.png?raw=true "Executing the Script")

This module contains two companion scripts:
- `rtd-update-system`: update OS packages (APT/YUM/Zypper/PKCON), snaps, and Flatpaks from one place
- `rtd-self-update`: update or reinitialize the RTD Power Tools installation from GitHub and rebuild launchers/themes

Both tools run independently of the rest of the stack and will elevate with `sudo/pkexec` when required.

## rtd-update-system
```bash
# interactive update of all package channels
rtd-update-system

# show updates installed today without performing an update
rtd-update-system --show

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
- reports counts for updates installed through native, Flatpak, and Snap channels; `--show` prints today's recorded updates without running an update
- logs to `/var/log/rtd/rtd-update-system.log`

## rtd-self-update
```bash
# update RTD Power Tools, menu launchers, and optional themes
rtd-self-update

# run with no prompts (assumes full update)
rtd-self-update --autoconfirm
```
What happens:
- prompts for which pieces to update (base tools, menu launchers, themes, or a clean reinitialize)
- stages fresh content from `https://github.com/<git_profile>/RTD-Setup` in a temporary directory
- by default, backs up `/opt/rtd` to a timestamped directory under `/opt/backup` and synchronizes new content into place with `rsync`, retaining unmatched local files
- theme updates likewise stage, back up, and synchronize themes into place without removing unmatched local files
- offers `Refresh/Reinitialize` when a clean replacement is needed; that path archives the previous install as a timestamped zip
- registers public module tools, removes legacy terminal links to internal core scripts, and recreates desktop/menu entries; logs to `/var/log/rtd`
