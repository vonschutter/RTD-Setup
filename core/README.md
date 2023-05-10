# RTD Power Tools Core
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

## Overview:

The core of the RTD Power Tools are the core libraries and the configuration scripts for computers, servers, and VMs. The core library and the configuration files are the following:

* _branding: Contains configurations for how things look
* _locations: Contains URL's, file locations, etc.
* _rtd_library: Contains all functions that do all the heavy lifting and repeated work.
* _rtd_library.ps1: Windows main configuration script (debloats, turns off tracking, and installs useful software)
* _rtd_recipies: Collections of software to make available for install.
* sigs (folder): contains the hashes used to validate the oem apps compressed in the /apps folder
* rtd-oem-enable-config.sh: script to enable the tools when auto installed via PRESEED, or AUTOUNATTEND.
* rtd-oem-linux-config.sh: script to configrure a server, VDI, VM, or PC using the _rtd_library functions
* rtd-oem-win10-config.ps1: script to configrure a server, VDI, VM, or PC

Further tools and utilities are located in the /apps folder and the /modules folder. These modules may make use of the _rtd_library accomplish their tasks. For example; the software-bundle-manager:![1683551411392](image/README/1683551411392.png)

NOTE: For the software bundle installer, and particularly for validating dependencies, software titles may be named slightly differently in some versions of Linux and may therefore not install since they are not found. For this reason, more emphasis is placed on "snap" apps and "flatpacks" where possible to allow universal installs. Snapps and Flatpaks allow for applications to be sandboxed for security as well.

The RTD Power Tools may be installed manually and/or added by either of PRESEED, KICKSTART, AUTOYAST, or AUTOUNATTEND installation configuration files. These configuration files are included by default in the RTD Power Tools Library and are created when needed. These are applied when either creating a VM or installation media using the RTD Power Tools.

| RTD Power Tools Active during a Windows 10 VM Build |
| --------------------------------------------------- |
| ![1683625615788](image/README/1683625615788.png)      |

## RTD Power Tools Library Usage:

The RTD Toolset is a collection of scripts intended to facilitate adding, optional and highly useful, software to a vanilla install of Debian, SUSE, or RedHat based distributions automatically. This tool could be useful for a smaller OEM to load systems in a consistent and easy way. Alternatively; an individual may simply want to have an easy way to reload or install another version of Linux without the hassle of adding all the software or answering all the setup questions.

 Consider this usecase: You want to move from one distribution to another. To move to a different distribution from the one that you are currently using all you would need to do is run the **rtd-me.sh.cmd** by opening a terminal and typing:

```
wget https://github.com/vonschutter/RTD-Build/raw/master/rtd-me.sh.cmd ; bash ./rtd-me.sh.cmd 
```

This is simply a convenient way to download and run the script **rtd-me.sh.cmd**. It will download all the tools needed for you to setup an automated thumbdrive or DVD install of fedora, Ubuntu, Kubuntu, Debian and more. rtd-simple-support-tool

many of the tools rely on the _rtd_library bash function library. To see what these functions are and write scripts that use them you may call the library like so:

To see options to use this library type:
``bash bash _rtd_library --help``

```bash
_rtd_library :: RunTime Data Library HELP ::

                        Usage: _rtd_library [OPTIONS]
                        valid option are :
                        --help           : Show this help text
                        --list           : List library functions (requires options: software, or internal, or all)
                                software : (list) software install bundles available
                                internal : (list) internal functions loaded
                                all      : (list) all library functions including software
                        --devhelp        : diplay script developer's help
                        EXAMPLE:
                        _rtd_library --list --internal
```

### DevHelp main dialog screen:

For example if you are using the tool remotely via SSH, you may display a help screen as illustrated below. This would facilitate working with scripts remotely.

To see useful documentation on each function in this library in a Terminal or remote ssh:
``bash bash _rtd_library --devhelp``

![1683618476060](image/README/1683618476060.png)

### DevHelp function description screen:

Once a function is selected the instructions are shown for how to use the function.

![1683618508270](image/README/1683618508270.png)

### DevHelpGtk main main dialog screen:

Handily if you are on a Linux desktop you may display library function documentation on your desktop using the --devhelp-gtk option.

To see useful documentation on each function in this library in GTK (local desktop):
``bash bash _rtd_library --devhelp-gtk``

![1683622846033](image/README/1683622846033.png)

### DevHelp function description screen:

As with the remote option, once selected the gtk dialogs will display documentation on how to use each function.

![1683623896061](image/README/1683623896061.png)

## Please consider sharing back and contributing:

These scripts are released for the convenience of all and are provided as is. However, all contributions are appreciated. The simplest way to contribute is to provide a shell script to be included in the /modules directory and the shell script itself named with the TLA "rtd'' so that the installer can find it and create a link in the $PATH.

If relevant the existing functions can be used that are present in the __rtd__library, alternatively, useful functions can be included in the RTD Library as well. To do this properly, functions should be added in the header documentation with a short description behind a ";" and the function itself should be documented as the other functions are in the library,such that the description will show up in the DevHelp options.
