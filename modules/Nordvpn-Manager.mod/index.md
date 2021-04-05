# RunTimeData Nordvpn Manager

![RTD CMD](Media_files/CMD.png?raw=true "Main Window")


This is a simple tool to make using NordVPN easier on Linux. By default NordVPN provides a command line way of interacting with NordVPN on Linux. This tool will make it much easier to connect to a speciffic country. Simply download this file and place it in a convenient location. We suggest placing it in a folder named "bin" in your home folder and make sure to make it executable (the example below). If you have purchased NordVPN but not installed it yet, this utillity will attempt to downloade it and install NordVPN for you. 


To install and use this tool on Linux (for example Ubuntu) simply open a terminal and cut and paste the line below in to the terminal window:

```
wget https://github.com/vonschutter/RTD-Nordvpn-Manager/blob/master/rtd-nordvpn -O ~/bin/ && chmod +x ~/bin/rtd-nordvpn && bash ~/bin/ 

```

## To do:
As time allows, this script may be extended:
- To work fully on other distribution platforms 
- Exposing the configuration elements of nordvpn as a GUI. 
- Adding support for using Zenity or KDE GUI menu elements for a full GUI experinece

NOTE: At present this script will use either whiptail (preffered) or dialog, depending on what it finds on the system. If neither is found it will try to install whiptail. If either whiptail or dialog is installed, and nordvpn is installed it should work fine on any distribution because they all support bash. 
