# RTD-VPN-Router
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) | 

![RTD Blind Install Media Header](Media_files/header-time.jpg "Executing the Script")
The RTD-VPN-Router is a simple script that you can use on a server, old PC, or a virtual machine at home or at a small business. It will automatically configure and setup that machine as a VPN router. 

After you have started the script you only have to direct all your traffic to the IP address of the VPN touter (the machine the script is running on) by updating the "gateway" of your DHCP service (usually on your internet router if you are a home user or small business). It is recommended that you set a static IP on the machine running the script or tell the router to always assigne the same IP to the PC used.

You may use any VPN software that you like for the actual VPN on the Linux server, however the script is preconfigured to use NordVPN by default. Remember to purchase the VPN service and note the credentials before starting the script.

For the simplest setup it is recommended that you install Debian or Ubuntu on the machine to be used as a VPN Router. 

### How to use the script...
If you have installed the RTD Power Tools (by running rtd-me.sh.cmd) simply type "rtd-start-vpn-router" in a terminal and hit enter.

If you have not, Simply cut and paste this command in to a terminal on your computer. This script can run independently as a stand alone tool.  

```bash

wget https://github.com/vonschutter/RTD-VPN-Router/raw/main/rtd-start-vpn-router && bash ./rtd-start-vpn-router 

```


Description | In this screen shot it is seen what the vpn router looks like in a terminal. This can be on a remote machine or local terminal; if you are disconnected or close the terminal, you may reconnect by simply typing "byobu" on the same machine that the vpn was started. 
------------ | -------------
VPN Router Running | ![RTD Builder Screenshot 2](Media_files/Scr1.png?raw=true "Executing the Script in a terminal")

***
![RTD Builder Screenshot 2](Media_files/Scr1.png?raw=true "Executing the Script in a terminal")
***

It would make me happy if any modification are shared back. 
