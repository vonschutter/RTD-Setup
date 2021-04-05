# RTD System Configurator: 
![RTD Builder Screenshot](Media_files/header-time.jpg "Executing the Script")

The RTD System Configurator intended to facilitate adding optional software and optimizing configuration of a vanilla install of Ubuntu, Debian (or derivatives), SUSE, Fedora, CentOS based distribution as well as Windows. The bootstrap script will identify Linux/Mac/BSD/Windows versions and execute those configurations scripts if they are defined. The non Linux or Windows references are essentially empty in the bootstrap script, due to lack of testing equipment. However, most of the software intended for Windows and Mac are proprietary and may not be distributed so only freely available software is added. Please keep in mind that this does not mean that the Open Source Software (OSS), or any of the free software in the Windows or linux repositories is less capable. You may well be able to do just about anything with OSS that you can do with proprietary software. The OSS does have one advantage though: it is peer reviewed and will unlikely come with built in back doors (intended or otherwise).   

If a graphical environment is not detected, the RTD System Configurator will interpret this as it is being run on a server without a graphical environment and will offer to setup the productivity tools for that environment. 

![RTD Builder Screenshot 2](Media_files/ScrTnGCombo.png?raw=true "Executing the Script")

As promised, the rtd-me.sh.cmd script will run under windows as well. Simply download it and double click on it (you will be prompted to elevate priviledges if needed). Please NOTE that at this time the windows functionality is roughly equivalent to the Linux twist, but will not prompt for anything, where as, for Linux the setup will pause for 60 seconds to allow for some selections. However, the script will optimize Windows by removing bloatware (Sponsored Software) and turning off services that most do not use to enhance both performance ad security. Several useful and fun software titles are automatically added. The windows changes are made with PowerShell. 

![RTD Builder Screenshot 2](Media_files/Scr11.png?raw=true "Executing the Script in Windows")

# RTD-Build

It would make me happy if any modification are shared back. Please read the license file for details. 

