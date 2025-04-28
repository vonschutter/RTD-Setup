#!/bin/bash
#
#::             	Linux software addon and configuration script
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Author(s):   	Vonschutter, KLS, NB.  Buffalo Center, IA & Avarua, Cook Islands
#:: Version 1.00
#::
#::
#::	Purpose: - The purpose of the script is to setup extra apps/config that is useful for a complete and productive environment.
#::		 - Feature: this script "detects" how to install and update software and and tweak the system.
#::		 - Flexible: This script works on several distributions of Linux since it uses "RTD Functions". Of course, you could
#::		   simply list all the "apt", "yum", or "zypper" commands along with the "snap" and "flatpak" to install
#::		   the software needed. However, you would likely need separate scripts for each distribution AND you
#::		   could not select or de-select software bundles or speciffic titles. This uses a GUI with a timeout for that.
#::		 - Smart: The "recipies" also downloads setup files from vendors with no repositories, and that do not have "snaps".
#::		 - Resiliant: This RTD installation system is therefore resiliant, stable, and flexible.
#::		 - NOTE: This script is installed to /opt/rtd/ by a wraper script "rtd-me.sh.cmd" that will work on many systems.
#::		 - NOTE: This script may also be used without the wrapper, once the wrapper has been run once and installed the
#::		   "RTD OEM Tools" to the system in question.
#::
#::	Dependencies:
#::	  _rtd_functions -- contain usefull admin functions for scripts, such as "how to install software" on different systems.
#::	  _rtd_recipies  -- contain software installation and configuration "recipies".
#::
#::
#::
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	NOTE:	This terminal program is written and documented to a very high degree. The reason for doing this is that
#		these apps are seldom changed and when they are, it is usefull to be able to understand why and how
#		things were built. Obviously, this becomes a useful learning tool as well; for all people that want to
#		learn how to write admin scripts. It is a good and necessary practice to document extensively and follow
#		patterns when building your own apps and config scripts. Failing to do so will result in a costly mess
#		for any organization after some years and people turnover.
#
#		As a general rule, we prefer using functions extensively because this makes it easier to manage the script
#		and facilitates several users working on the same scripts over time.
#
#
#	RTD admin scrips are placed in /opt/rtd/scripts. Optionally scripts may use the common
#	functions in _rtd_functions and _rtd_recipies.
#
#	Taxonomy of this script: we prioritize the use of functions over monolithic script writing, and proper indentation
#	to make the script more readable. Each function shall also be documented to the point of the obvious.
#	Suggested function structure per google guidelines:
#
#	function_name () {
#		# Documentation and comments...
#		...code...
#	}
#
#	We also like to log all activity, and to echo status output to the screen in a frienly way. To accomplish this,
#	the table below may be used as appropriate:
#


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Variables that govern the behavior or the script and location of files are
# set here. There should be no reason to change any of this.

# Use the RTD function library. This contains most of the intelligence used to perform this systems
# maintenance. This will allso enable color some easily referenced color prompts:
# $YELLOW, $RED, $ENDCOLOR (reset), $GREEN, $BLUE etc.
# As this library is required for basically everything, we should exit if it is not available.
# Logically, this script will not run, ever, unless downloaded along with the functions and the
# rtd software recipie book by rtd-me.sh, or on a RTD OEM system where these components would have been
# downloaded by the preseed or kickstart process as part of the install.
: ${_SCRIPTNAME="$(basename $0)"}
: ${_TLA:="${_SCRIPTNAME:0:3}"}
: ${_LOG_DIR:="/var/log/rtd"} ; mkdir -p ${_LOG_DIR}

# Determine log file directory
_LOGFILE=${_LOG_DIR}/$( basename $0).log

# Normally all choices are checked. Pass the variable "false" to this script to default
# to unchecked. If none is passed, a default will be used.
export zstatus="$1"

# Set the background tilte:
: "${_BACK_TITLE:="RTD OEM Simple System Setup"}"

# List of bare minimum managmement software that shuold be on a system
_requirements="dialog wget curl rsync git"

[ "$UID" -eq 0 ] || exec sudo -E -H /bin/bash "$0" "$@" 
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Functions                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


complete_setup () {
	#conditional default value option for the OEM reaseal
	if hostnamectl |grep "Ubuntu" 2>/dev/null ; then
		ConditionalResealOption="Reseal system and prepare for delivery to new user"
	elif hostnamectl |grep "Pop!_OS" 2>/dev/null ; then
		ConditionalResealOption="Reseal system and prepare for delivery to new user"
	else
		unset ConditionalResealOption
	fi

	completion=$(printf "Restart system and start using it now\nExit now and do no more\n${ConditionalResealOption}\n" | zenity \
				--list \
				--title "System Setup Complete" \
				--text "<span font="16" foreground="red"> 🚧 System Setup Complete 🚧</span> \n Please select if you witsh to reseal the system (not available for some distributtions), restart and use the system, or just exit" \
				--column "Options" --width=1024 --height=768  2>/dev/null )
	case "$completion" in
		"Restart system and start using it now" )
			write_information "Restarting system..." 
			reboot
			exit 0
		;;
		"${ConditionalResealOption:-"Ignore"}" )
			write_information "Resealing system..." 
			system::rtd_oem_reseal
			exit 0
		;;
		"Exit now and do no more" )
			write_information "Quitting..." 
			exit 0
		;;
		* ) echo "Unknown exit option (ESC?)"
			exit 12 
		;;
	esac
}




dependency_rtd_library ()
{
	_src_url=https://github.com/${_GIT_PROFILE}/RTD-Setup/raw/main/core/_rtd_library

	if source "$( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../core/_rtd_library ; then
		write_information "${FUNCNAME[0]} 1 Using:  $( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../core/_rtd_library
	elif source "$( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../../core/_rtd_library ; then
		write_information "${FUNCNAME[0]} 2 Using:  $( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../core/_rtd_library
	elif source $(find /opt -name _rtd_library |grep -v bakup ) ; then
		write_information "${FUNCNAME[0]} 3 Using: $(find /opt -name _rtd_library |grep -v bakup )"
	elif wget ${_src_url} ; then
                write_information "${FUNCNAME[0]} 4 Using: ${_src_url}"
		source ./_rtd_library 
	else
		echo -e "RTD functions NOT found!" 
		return 1
	fi
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Execute tasks                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Ensure that this script is run with administrative priveledges such that it may
# alter system wide configuration.
# ensure_admin




oem_linux_config ()
{
	if [[ ! $UID -eq 0 ]]; then
		echo -e "🛡️ This script needs administrative access..."
		# Relaunch script in priviledged mode...
		sudo -E bash $0 $*
	else
		if [ -z "${RTDFUNCTIONS}" ]; then
			dependency_rtd_library || { echo "📚 Failed to find _rtd_library"; exit 1; }
		else
			write_information "📚 _rtd_library is already loaded..."
		fi

		system::wait_for_internet_availability

		for i in $_requirements ; do 
			software::check_native_package_dependency $i
		done

		oem::rtd_reset_default_environment_config

		if [[ -z "$(ps aux |grep X |grep -v grep)" ]]; then
			echo "No X server at \$DISPLAY [$DISPLAY]"
			if ! hash dialog &>/dev/null ; then software::check_native_package_dependency dialog || exit 1 ; fi
			oem::setup_choices_server
		else
			if ! hash zenity &>/dev/null ; then  software::check_native_package_dependency zenity || exit 1 ; fi
			if ! hash yad &>/dev/null  ; then software::check_native_package_dependency yad || write_warning "YAD is not installed. Some features will not be available." ; fi

			if [[ -e ${_THEME_DIR}/plus-themes.sh ]] ; then
				write_information "🔮 Found plus-themes.sh in ${_THEME_DIR}"
			else
				write_information "🔮 Downloading plus-themes.sh to ${_THEME_DIR}"
				oem::deploy_themes
			fi
			
			bash ${_MODS_DIR}/oem-bundle-manager.mod/rtd-oem-bundle-manager 
			complete_setup
		fi
	fi
}

oem_linux_config $zstatus

exit
EOF
