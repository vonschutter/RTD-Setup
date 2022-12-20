#!/bin/bash
PUBLICATION="RTD Simple Global Theme Install"
VERSION="1.00"
#
#::             Linux Theme Installer Script
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Linux //::::
#:: Author(s):   	SLS
#:: Version 1.00
#::
#::
#::	Purpose: The purpose of this script is to install all relevant themes in th folders ico, kde, and gtk
#::		 found in the current dicectory. It will extract the 7z compressed files, and look for install.sh in
#::		 folder and run it.
#::
#::	Dependencies: - There may be dependencies like make and other development utilities.
#::		      - It is also assumed that there is an "install.sh" script in the root of each compressed archive. 
#::			This script may be supplied by the maintainer of the theme or us/you. It shall, by default, 
#::			install a sensible set of theme files (icons, themes, colors etc.).
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
: "${_my_scriptdir="$( cd "$( dirname ${BASH_SOURCE[0]} )" && pwd )"}"
: "${_tmp="$( mktemp -d )"}" 
: "${_GIT_PROFILE:-"vonschutter"}"

_potential_dependencies="7z unzip p7zip-full p7zip p7zip-plugins sassc gettext make"


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Functions                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

theme::install_payload ()
{
	for i in *.7z ; do
		7z x $i -aoa -o${_tmp}
		pushd "${_tmp}/${i::-3}"
		bash ./install.sh
		popd
	done
}

theme::add_global ()
{
	case $1 in
	--gtk )
		pushd ${_my_scriptdir}/gtk
		theme::install_payload
		ensure_snap_package_managment
		snap install vimix-themes && for i in $(snap connections | grep gtk-common-themes:gtk-3-themes | awk '{print $2}'); do sudo snap connect $i vimix-themes:gtk-3-themes; done
		popd
	;;
	--kde )
		pushd ${_my_scriptdir}/kde
		theme::install_payload
		popd
	;;
	--fonts) 
		pushd ${_my_scriptdir}/fon
		theme::install_payload
		popd
	;;
	*)
		echo "Neither GTK or KDE themes were requested"
	;;
esac
}
l
theme::install_icons ()
{
	pushd ${_my_scriptdir}/ico
	for i in *.7z ; do
		7z x $i -aoa -o${_tmp}
		pushd "${_tmp}/${i::-3}"
		bash ./install.sh
		popd
	done
}


dependency::_rtd_library ()
{
	_src_url=https://github.com/${_GIT_PROFILE}/RTD-Setup/raw/main/core/_rtd_library

	if source "$( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../../core/_rtd_library ; then
		write_information "${FUNCNAME[0]} 1 Using:  $( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../../core/_rtd_library
	elif source $(find /opt -name _rtd_library |grep -v bakup ) ; then
		write_information "${FUNCNAME[0]} 2 Using: $(find /opt -name _rtd_library |grep -v bakup )"
	elif wget ${_src_url} ; then
		source ./_rtd_library
	else
		echo -e "RTD functions NOT loaded!"
		echo -e " "
		echo -e "Cannot ensure that the correct functionality is available"
		echo -e "Quiting rather than cause potential damage..."
		return 1
	fi
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Execute tasks                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

dependency::_rtd_library && for i in "${_potential_dependencies}" ; do hash $i || check_dependencies $i ; done


case $1 in
	--gtk )
		echo "Foced install of GTK themes..."
		theme::add_global --gtk
		theme::install_icons
		theme::add_global --fonts
	;;
	--kde )
		echo "Foced install of KDE themes..."
		theme::add_global --kde
		theme::install_icons
		theme::add_global --fonts
	;;
	--all )
		echo "Foced install of ALL themes..."
		theme::add_global --kde
		theme::add_global --gtk
		theme::install_icons
		theme::add_global --fonts
	;;
	* )
		echo "No preference stated. Autodetecting themes for current environment..."
		if  ps -e |grep "plasmashell" ; then
			theme::add_global --kde
			theme::install_icons
			theme::add_global --fonts
		elif  ps -e |grep "gnome-shell"; then
			theme::add_global --gtk
			theme::install_icons
			theme::add_global --fonts
		else
			echo "Neither plasma or gnome was found! Only installing Icons."
			theme::install_icons
			theme::add_global --fonts
		fi
	;;
esac


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Finalize.....                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
unset _my_scriptdir
unset _potential_dependencies
exit

