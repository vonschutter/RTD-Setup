# RTD Minecraft Server Manager
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

![RTD Blind Install Media Header](Media_files/header-time.jpg "Executing the Script")
The minecraft server launcher script. Setting up your own Minecraft server on Ubuntu has never been easier! Just launch the script and it will do the rest! 

## Purpose:
This is a tool to help users who come to Linux from a different OS.

## How to use this script. 
To use this script just download this script (minecraft.server) to your home folder and run it. It will automatically: 

1. Install or reuse a handy Ubuntu server or desktop system. 
2. SSH to your Ubuntu system or open a terminal if you are using your Ubuntu Desktop. 
3. To download and optionally install the latest Minecraft (you may cut and paste the line below):

```bash
wget https://github.com/vonschutter/RTD-Minecraft-Server-Manager/raw/master/minecraft-server -O ~/minecraft-server && chmod +x ~/minecraft-server && ~/minecraft-server
```

4. Then to run the RTD-Minecraft-Server-Manager next time you want to by typing: 

```bash
~/minecraft.server
```

As of version 1.02 you can also launch the "minecraft.server" with the "--update" option to download the latest minecraft version automatically. 

```bash
~/minecraft.server --update
```

## Features:
When the RTD-Minecraft-Server-Manager is started, it will do the collowing.

- Check and see if Minecraft is installed in the expected localion on the server. 
- If no server is found in the expected location, one will be downloaded.
- Check that the relevant scripts and configuration files are in the expected locations. 
- If the configuration files are not found, the script will get basic working configuration files.
- Check if the required software is available:
-   Install Java if not there
-   Install the software needed by the console if not there
- When all of the above is satisfied the server luncher console is started
