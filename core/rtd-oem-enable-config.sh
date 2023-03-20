#!/bin/bash
#
#::                             S Y S T E M    B U I L D     C O M P O N E N T
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::// OEM ENABLE CONFIG //::::::::::::::::::::::::::::::::::// Linux //::::::::
#::
#:: Author:   	SLS
#:: Version 	1.02
#::
#::
#::	Purpose: To enable configuration of a newly built linux install. This file will be referenced by
#::		 either Debian setup (Debian , ubuntu, etc.), SUSE auto yast, or Anaconda (red Hat, Fedora etc.).
#::		 This script configures the system to auto login, and run the systen configuration choices menu.
#::
#::	Usage:	Simply execute this script to accomplish this task. No parameters required.
#::
#::
#::
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
# This script is shared in the hopes that someone will find it useful.
# For convenience and supportability most actions (work) is stored in a common library used bu multiple scripts.
# To use these functions in the library, simply load the library using the "source" bash built in command. All
# functions will then be available for use. This script demonstrates the simplicity of using these functions.
#
# This script is intended to live in the ~/bin/ or /bin/ folder, alternatively in the $PATH.
# By default this script is placed in /opt/rtd/core/
#
# NOTE: this script is run by the power tools system setup and therefore the oem tools are asumed to be present.
#
# 1 - To see options to use the rtd library type: "bash _rtd_library --help"
# 2 - To see usefull documentation on each function in this library: "bash _rtd_library --devhelp or --devhelp-gtk"

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Variables that govern the behavior or the script and location of files are

# Base folder structure for optional administrative commandlets and scripts:
# Put a convenient link to the logs where logs are normally found...
# capture the 3 first letters as org TLA (Three Letter Acronym)
export _SCRIPTNAME=$(basename $0)
export _TLA=${_SCRIPTNAME:0:3}
source /opt/${_TLA,,}/core/_rtd_library
mkdir -p ${_LOG_DIR}

# Determine log file directory
_LOGFILE=${_LOG_DIR}/$( basename $0).log



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Execute tasks                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


toggle_oem_run_once "/opt/rtd/core/rtd-oem-linux-config.sh"	&>> $_LOGFILE
set_enable_oem_elevated_privelege	        		&>> $_LOGFILE
toggle_oem_auto_login						&>> $_LOGFILE
set_oem_elevated_privilege_gui					&>> $_LOGFILE
oem::rtd_tools_make_launchers					&>> $_LOGFILE
oem::register_all_tools						&>> $_LOGFILE
ln -s -f ${_LOG_DIR} -T ${_OEM_DIR}/log				&>> $_LOGFILE
