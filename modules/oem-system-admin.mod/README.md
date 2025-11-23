# System Admin Tools

< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

![RTD Blind Install Media Header](https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/media_files/header-time.jpg "Executing the Script")

## Purpose: To simplify common support tasks

        - Compress and encrypt items in a folder
        - Update system software
        - Backup files and folders in to encrypted archives
        - Cleanup/Report on PPA's
        - Cleanup and decruft Debian based systems
        - Show systems physical location
        - Add an Ubuntu system to the Landscape managment
        - configure hardware
        - Reset sound system
        - Get Windows key from BIOS
        - Move media files of certain types to common location
        - Clear out zombie processes
        - etc.

Generally the scripts herein are entry points to functions in the `_rtd_library`. The quickest way to explore them is to launch the menu helper:
```bash
rtd-script-menu
```
Zenity will list every `rtd-*` helper in this module and run the one you select.

## Included scripts (high level)
- `rtd-7z-this`, `rtd-7z-all-files-here`, `rtd-7z-encrypt-this`, `rtd-7z-encrypt-all-files-here`: 7z compression helpers with optional AES encryption
- `rtd-add-ubuntu-to-landscape-onprem`: enroll a system into Landscape
- `rtd-burniso`, `rtd-make-bootable-usb-drive`, `rtd-make-bootable-cd`: write install media to USB or optical discs
- `rtd-clear_iptables`, `rtd-start-routes`, `rtd-netuse`: network cleanup, routing, and bandwidth monitoring
- `rtd-clear-zombie`, `rtd-restart-sound`, `rtd-tracker-force-update`, `rtd-xterm-sysconsole`: day-to-day remediation tasks (process cleanup, sound reset, tracker refresh, terminal console)
- `rtd-configure-huion`: configure Huion tablets
- `rtd-deb-cleanup`, `rtd-oem-old-kernel-remover`, `rtd-ppa-checker`: package and repo maintenance
- `rtd-dropbox-on-ecryptfs`: enable Dropbox sync on encrypted home folders
- `rtd-get-Windows-product-key`: retrieve the OEM Windows key from BIOS/UEFI
- `rtd-internet-location`: show the public IP and geographic location
- `rtd-malware-scan`, `rtd-malware-scan-HOME`: run clamav scans across the system or home
- `rtd-organize-everything`, `rtd-mv`, `rtd-unrar-all`, `rtd-join-avi`, `rtd-make-swap`: file organization, extraction, and swap creation helpers
- `rtd-ssh-connection-list-local`: list incoming SSH connections
- `rtd-on-notify-wait`: wait on a file or process and then notify

Each script is self contained; run any of them directly from a terminal (for example `rtd-ppa-checker`). When launched through the Power Tools installer they will use the shared logging and dependency helpers from `_rtd_library`.
