# Simple Support Tool
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) | 

![RTD Blind Install Media Header](Media_files/header-time.jpg "Executing the Script")

###	Purpose: To simplify support tasks 

	- Display system information 
	- Update system software
	- Backup virtual machines 
	- Cleanup/Report on PPA's
	- Show systems physical location 
	- Check if a password you intend to use is for sale on the Darknet

![RTD SSST](Media_files/0-amalgam.png?raw=true "Main Window")

You may can run the script on any remote Linux server to manage some common support tasks. This tools should work on any deb or rpm based system or any system that uses package kit to satisfy dependencies and update the system. It uses standard tools available in Lnux and in common repositories to manage the systems. 

Please NOTE that this script is part of the RTD tools and requires the _rtd_library to function properly. 

![RTD SSST](Media_files/1-main_menu.png?raw=true "Main Window")
This tool is documented as well as can be. It It may also easily be extended/modified to do whatever a sysadmin would like it to since it contains menu templates and is written in a moduar way. 

```bash
# Usage: 
bash /path/to/rtd-simple-support-tool
# if in $PATH; simply type:
rtd-simple-support-tool
```

