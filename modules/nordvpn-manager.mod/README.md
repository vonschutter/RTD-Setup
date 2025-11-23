# RTD NordVPN Manager
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

![RTD CMD](Media_files/header-time.jpg?raw=true "Header")

This is a simple wrapper for the nordvpn CLI. It essentially makes the basic and most used functionality as a CLI GUI. At present this script will use either whiptail (preffered) or dialog, depending on what it finds on the system. If neither is found it will try to install whiptail. If either whiptail or dialog is installed, and nordvpn is installed it should work fine on any distribution because they all support bash. 

![RTD CMD](Media_files/CMD.png?raw=true "Main Window")

## How it works
- Detects `whiptail` or `dialog` for menu rendering (will offer to install if missing)
- Checks for the `nordvpn` CLI; if missing it can pull the official DEB/RPM release and set it up
- Presents a country list (plus “nearest server”) and connects via the official `nordvpn connect` command
- Keeps the session status visible and offers a quick disconnect path

## Usage
```bash
rtd-nordvpn
```
Follow the prompts to install the NordVPN client when needed, pick a country, and connect. If you cancel the country menu, the tool disconnects and exits cleanly.

## To do:
As time allows, this script may be extended:
- To work fully on other distribution platforms 
- Exposing the configuration elements of nordvpn as a GUI. 
- Adding support for using Zenity or KDE GUI manu elements for a full GUI experinece

