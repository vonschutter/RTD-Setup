# RTD-VPN-Router

The RTD-VPN-Router is a simple script that you can use on a server, old PC, or a virtual machine at home or at a small business. It will automatically configure and setup that machine as a VPN router. 

After you have started the script you only have to direct all your traffic to the IP address of the VPN touter by updating the "gateway" on your DHCP service (usually on your internet router if you are a home user or small business). It is recommended that you set a static IP on the machine running the script.

You may use any VPN software that you like for the actual VPN on the Linux server, however the script is preconfigured to use NordVPN by default. Remember to purchase the VPN service and note the credentials before starting the script.

For the simplest setup it is recommended that you install Debian or Ubuntu on the machine to be used as a VPN Router. 

### How to use the script...
Simply cut and paste this command in to a terminal on your computer.  

```

wget https://github.com/vonschutter/RTD-VPN-Router/raw/main/rtd-start-vpn-router && bash ./rtd-start-vpn-router 

```

![RTD Builder Screenshot 2](Media_files/Scr1.png?raw=true "Executing the Script in a terminal")


It would make me happy if any modification are shared back. 
