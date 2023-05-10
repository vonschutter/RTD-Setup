# Power Tools Script Module Directory
< [Back](https://github.com/vonschutter/RTD-Setup/blob/main/README.md) |

This is the location of scripts that can be used as part of the Power Tools.

### Overview:

A folder residing in the "modules" directory will be scanned for script names beginning with the configured $_TLA in the _branding config file. In this case "rtd" is the configured and default TLA. Any file named rtd* will be made executable and a link placed in the path of the shell environment so that it will be accessible in all bash shell prompts.

It is good for to include a README file that explains the function of the contributed script and how to use it.

```ini
[ modules ] (root directory of addon modules)
    [name].mod (name of contributio or function of contained scripts)    	 
         rtd-name-of-script   
         README.md (description of what the script does)
```


The default modules for the RTD Power Tools are:

1. RTD-Desktop-Look-Switcher: used to change the overall look of Gnome for Wondows and Mac refugees
2. RTD-OEM-bundle-manager: used to add and remove bundles of software quickly and easily
3. RTD_OEM-System_Admin: system support tools
4. RTD-VPN-Router: quick setup of a pc or VM as a VPN router (routing all traffic coming to it othrouugh a VPN)
