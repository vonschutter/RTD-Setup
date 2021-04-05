# RTD Nordvpn Manager

![RTD CMD](Media_files/CMD.png?raw=true "Main Window")


This is a simple wrapper for the nordvpn CLI. It essentially makes the basic and most used functionality as a CLI GUI. At present this script will use either whiptail (preffered) or dialog, depending on what it finds on the system. If neither is found it will try to install whiptail. If either whiptail or dialog is installed, and nordvpn is installed it should work fine on any distribution because they all support bash. 

## To do:
As time allows, this script may be extended:
- To work fully on other distribution platforms 
- Exposing the configuration elements of nordvpn as a GUI. 
- Adding support for using Zenity or KDE GUI manu elements for a full GUI experinece


