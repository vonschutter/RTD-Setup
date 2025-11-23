# RunTimeData Nordvpn Manager

![RTD CMD](Media_files/CMD.png?raw=true "Main Window")


This wrapper makes the NordVPN CLI usable from a simple terminal menu. It installs `whiptail`/`dialog` as needed, installs the official NordVPN package if missing, then lets you pick a country (or “nearest”) and connects.

### Install and run
```bash
# use RTD-installed binary
rtd-nordvpn

# or fetch just this script
wget https://github.com/vonschutter/RTD-Setup/raw/main/modules/nordvpn-manager.mod/rtd-nordvpn -O ~/bin/rtd-nordvpn
chmod +x ~/bin/rtd-nordvpn && ~/bin/rtd-nordvpn
```

## To do
- Expose more NordVPN config toggles (kill switch, DNS, protocol, obfuscation)
- GUI front-end via Zenity/KDialog when available
