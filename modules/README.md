# Power Tools Script Module Directory

This is the location of scripts that can be used as part of the Power Tools. 


### Hierarchy:

A folder residing in the "modules" directory will be scanned for script names beginning with the configured $_TLA in the _branding config file. In this case "rtd" is the configured and default TLA. Any file named rtd* will be made executable and a link placed in the path of the shell environment so that it will be accessible in all bash shell prompts.

It is good for to include a README file that explains the function of the contributed script and how to use it. 

```
[ modules ] (root directory of addon modules)
    [name] (name of contributio or function of contained scripts)    	 
         rtd-name-of-script   
         README.md (description of what the script does)
```
