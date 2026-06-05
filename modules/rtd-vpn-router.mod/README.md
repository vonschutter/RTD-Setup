# RTD-VPN-Router
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) | 

![RTD Blind Install Media Header](Media_files/header-time.jpg "Executing the Script")
The RTD-VPN-Router is a hardened Bash script that turns a Linux host (server, old PC, or VM) into a VPN router. It sets firewall rules to force all LAN traffic through the VPN tunnel and **fails closed** if the tunnel drops, preventing leaks.

After you have started the script you only have to direct all your traffic to the IP address of the VPN router (the machine the script is running on) by updating the "gateway" of your DHCP service (usually on your internet router if you are a home user or small business). It is recommended that you set a static IP on the machine running the script or tell the router to always assign the same IP to the PC used.

Supported VPN providers:
- **NordVPN** (auto-installs if selected)
- **Mullvad VPN** (adds the official repo then installs)
- **Proton VPN** (adds the official repo then installs)

The script auto-detects any of these clients already present. If none are found, it will prompt you to choose which one to install, add the official repository, and install the client, then start the VPN. Bring your own credentials/config for the chosen provider.

For the simplest setup it is recommended that you install Debian or Ubuntu on the machine to be used as a VPN Router. RPM-based distros are supported for the VPN installers as well. The script requires sudo/root access to configure networking and firewall rules.

### How to use the script...
If you have installed the RTD Power Tools (by running rtd-me.sh.cmd) simply type "rtd-start-vpn-router" in a terminal and hit enter.

On a normal interactive run, the script connects the selected VPN client, detects the VPN tunnel, applies the routing/firewall rules, and opens the byobu monitoring view.

If the systemd service is already active and you run `rtd-start-vpn-router` with no parameters, the script assumes the router is already up. In that case it opens the monitoring view only; it does not start another VPN connection or reapply routing rules.

If you have not, Simply cut and paste this command in to a terminal on your computer. This script can run independently as a stand alone tool.  

```sh

wget https://github.com/vonschutter/RTD-Setup/raw/main/modules/rtd-vpn-router.mod/rtd-start-vpn-router && bash ./rtd-start-vpn-router 

```

### Install as a service

To start the VPN router automatically after reboot:

```sh
sudo rtd-start-vpn-router --install
```

This installs the script as `rtd-vpn-router.service`, enables it, and starts it immediately. The service runs non-interactively and keeps the router process alive through the log file. To watch an already-running service, launch:

```sh
sudo rtd-start-vpn-router
```

The no-parameter monitor-only behavior can be disabled with:

```sh
sudo VPN_ROUTER_MONITOR_ONLY_WHEN_SERVICE_ACTIVE=0 rtd-start-vpn-router
```

Useful service-related settings:

| Setting | Purpose |
| --- | --- |
| `VPN_ROUTER_SERVICE_NAME` | Systemd service name. Default: `rtd-vpn-router.service` |
| `VPN_ROUTER_INSTALL_PATH` | Installed script path. Default: `/usr/local/sbin/rtd-start-vpn-router` |
| `VPN_ROUTER_RUN_USER` | User home used for monitor sessions when running from service/root |
| `VPN_ROUTER_LOGFILE` | Log pane file. Default: `/var/log/rtd/rtd-vpn-router.log` |
| `VPN_ROUTER_MONITOR_ONLY_WHEN_SERVICE_ACTIVE` | With no parameters, monitor an active service instead of starting a second VPN connection |


Description | In this screen shot it is seen what the vpn router looks like in a terminal. This can be on a remote machine or local terminal; if you are disconnected or close the terminal, you may reconnect by simply typing "byobu" on the same machine that the vpn was started. 
------------ | -------------
VPN Router Running | ![RTD Builder Screenshot 2](Media_files/Scr1.png?raw=true "Executing the Script in a terminal")


It would make me happy if any modification are shared back. 
