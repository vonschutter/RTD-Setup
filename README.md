# RTD Power Tools                          <img src="media_files/WindowsLogo.png" width="24" height="24"> <img src="media_files/UbuntuLogo.png" width="24" height="24">  <img src="media_files/RedHatLogo.png" width="24" height="24">  <img src="media_files/SuseLogo.png" width="32" height="24"> 
[MinecraftServer](https://github.com/vonschutter/RTD-Setup/blob/main/modules/Minecraft-Server-Manager.mod/README.md) | [NordVPN_GUI](https://github.com/vonschutter/RTD-Setup/blob/main/modules/Nordvpn-Manager.mod/README.md) | [DesktopLookSwitcher](modules/RTD-Desktop-Look-Switcher.mod/README.md) | [Instant VPN Router](/modules/RTD-VPN-Router.mod/README.md) | [Simple Support Tool](/modules/Simple-Support-Tool.mod/README.md)

![RTD Builder Screenshot](media_files/header-time.jpg "Header")

# What Are the RTD Power Tools:

These Power Tools are created to simplify the life of an enthusiast, a system administrator or developer. If you are the person who lives and breathes in the terminal and know every single system command in the back of your head like a reflex, and you don't mind typing several hundred characters each time you want to, for example, build a VM to test your stuff; this may not be as valuable to you. The purpose of these tools are to expose common tasks and automate them so all you need to do is a few up/down arrows and selections.  Some tools included are (usable over an ssh connection).

Running the RTD-Setup (rtd-me.sh.cmd) will give you:
- Software Productivity Bundle installer (auto run the first time)
- Global system update tool to update native packages, flatpaks, and snaps.
- Auto VM builder for Debian, Ubuntu, SUSE, Fedora, and Windows 10
- Debian system cleanup tool
- Add system to an on-premise Ubuntu Landscape Server
- Desktop Installation media creator for Debian and Ubuntu Desktops
- Server Installation media creator for Ubuntu, Debian and Minecraft servers
- Viewing system information
- Removing unused PPA repositories
- Term GUI for NordVPN
- Instant VPN router setup
- and more...

Just type "rtd" and hit [TAB] once or twice to see all the tools available at the terminal. The main tools are available in the OEM or "other" category in the menu/launcher in Linux.

<kbd> ![RTD Builder Screenshot 2](media_files/ScrRTDTerm.png) </kbd> 

## On Linux
The RTD Setup includes the **Software Bundle Installer** intended to facilitate adding optional software and optimizing configuration of a vanilla install of Ubuntu, Debian (or derivatives), SUSE, Fedora, CentOS based distribution as well as Windows. The bootstrap script (**rtd-me.sh.cmd**) will identify Linux/Mac/BSD/Windows versions and execute those configurations scripts if they are defined. The non Linux or Windows references are essentially empty in the bootstrap script at present, due to lack of testing equipment. However, most of the software intended for Windows and Mac are proprietary and may not be distributed so only freely available software is added. Please keep in mind that this does not mean that the Open Source Software (OSS), or any of the free software in the Windows or linux repositories is less capable. You may well be able to do just about anything with OSS that you can do with proprietary software. The OSS does have one advantage though: it is peer reviewed and will unlikely come with built in back doors (intended or otherwise).  

Running "rtd-oem-linux-config.sh" (**Software Bundle Installer**) in Debian (also run when installing RTD Power Tools):

<kbd> ![RTD Builder Screenshot 2](media_files/ScrGnoDeskoem.png) </kbd> 

If a graphical environment is not detected, the RTD System Configurator will interpret this as it is being run on a server without a graphical environment and will offer to set up the productivity tools for that environment.

<kbd> ![RTD Builder Screenshot 2](media_files/ScrTermOEMSetup.png) </kbd> 

## On Windows
As promised, the rtd-me.sh.cmd script will run under windows as well. Simply download it and double click on it (you will be prompted to elevate privileges if needed). Please NOTE: that at this time the Windows functionality is roughly equivalent to the Linux **Software Bundle Installer**, but will not prompt for anything, whereas for Linux the setup will pause for 60 seconds to allow for some selections. However, the script will optimize Windows by removing bloatware (Sponsored Software) and turning off services that most do not use to enhance both performance and security. Several useful and fun software titles are automatically added (will not fill up your disk). The Windows changes are made with PowerShell.

Running "rtd-oem-win10-config.ps1" (**Software Bundle Installer**) in Windows (also run when installing RTD Power Tools):

<kbd> <img src="media_files/Scr11.png" > </kbd> 

# How to Install RTD Power Tools:
Getting the RTD power Tools has been made as easy as possible. The installation process simply involves downloading and running a single script. This script will make these tools available on you system with a minimum of questions. 

## Installing In Linux
To get these tools for yourself on Linux just copy and paste the line below in to a terminal:

```bash
wget https://github.com/vonschutter/RTD-Setup/raw/main/rtd-me.sh.cmd && bash ./rtd-me.sh.cmd
```
Please note that you will need elevated priviledges on the Linux system (root).

If you are using Windows Subsystem for Linux (WSL) you may copy and paste the same in to your WSL terminal window to use this in WSL. 

## Installing In Windows
If you want to run the **Software Bundle Installer** (and optimizer) in Windows 10; please use the link below to save the script locally. Since it does not make sense to use linux tools in Windows, the power tools themselves are not made available in the Windows environment; but, since the power tools do include an option for automatically building a Windows Desktop Virtual Machine (VDI) in Linux; the **Software Bundle Installer** for Windows will be run for you automatically inside the Virtual Machine by downloading and executing **rtd-me.sh.cmd** in the VM. 


On Windows rtd-me.sh.cmd will automatically:
- Add a proper package manager for you (chocolatey)
- Install some useful OSS software (Libre Office, Secure internet browsers and communication tools)
- Debloat Windows (disabling services, telemetry, software not used)
- Fix some minor security settings
- Make some UI Tweaks for better usability

Download:
[Direct Download Link](https://github.com/vonschutter/RTD-Setup/raw/main/rtd-me.sh.cmd)
```
https://github.com/vonschutter/RTD-Setup/raw/main/rtd-me.sh.cmd
```
Running RTD Power Tools to add software to WSL in Windows:
<kbd> ![RTD Builder Screenshot 2](media_files/ScrWinWSL.png?raw=true "Executing the Script in WSL")</kbd> 
l

# Please Share Back:
It would make me happy if any modifications are shared back, or if any suggestions could be shared. Please read the license file for details. 
