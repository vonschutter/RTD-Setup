#!/bin/bash
#
#::             			A D M I N   C O M M A N D L E T
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::// Simple Admin Tool //::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#::
#::     Author:   	SLS
#::     Version 	1.02
:	${GIT_Profile:=vonschutter}
#::
#::                -------------------------
#::
#::	Thursday 29 September 2005  - SLS
#::		* File originally created.
#::
#::
#::	Purpose: to mount all the SMB/Windows shares indicated in this script on the server specified.
#::		 There is no limit to the number of shares that you can mount.
#::
#::
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
# This script was originally developed for RuntimeData, a small OEM in Buffalo Center, IA.
# This OEM and store nolonger exists as its owner has passed away.
# This script is shared in the hopes that someone will find it usefull.



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        # // edit this to reflect the server you want to connect to //
        # // and the shares as well                                 //
        _shares=$( echo ${@} |cut  -d' ' -f2- )
        _server=$1

        # // you do not need to edit these lines or any remaining  //
        # // lines in this script                                  //

        ANS=$(dialog --stdout --title "SMB password" --passwordbox Password: 10 60)
        clear
	_opt="username=$USER,password=$ANS"
        _mnt=/home/$USER/mnt


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Functions                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

check_rtd_library ()
{
	_src_url=https://github.com/${_GIT_PROFILE}/RTD-Setup/raw/main/core/_rtd_library

	if source "$( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../../core/_rtd_library ; then
		# Library found in relative path...
		write_information "${FUNCNAME[0]} 1 Using:  $( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" && pwd )"/../../core/_rtd_library
	elif source $(find /opt -name _rtd_library |grep -v bakup ) ; then
		# Library not found in relative path: search the typical location...
		write_information "${FUNCNAME[0]} 2 Using: $(find /opt -name _rtd_library |grep -v bakup )"
	elif wget ${_src_url} ; then
		# Critical failure: downloaded copy from github.com
		source ./_rtd_library
	else
		# Abot condition: No mitigation steps worked.
		echo -e "RTD functions NOT loaded!"
		echo -e " "
		echo -e "Cannot ensure that the correct functionality is available"
		echo -e "Quiting rather than cause potential damage..."
		exit 1
	fi
}



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Executive                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo server=$_server
echo shares=$_shares


connect_to_shares ()
{
        for _arg in $_shares
                do
                        if [ -e $_mnt/$_arg ]; then
                        	echo "mount point $_mnt/$_arg is there..."
                        	smbmount //$_server/$_arg $_mnt/$_arg -o $_opt

                        	else
                        	echo "mount point $_mnt/$_arg is not there..."
                        	echo "creating mount point"
                        	mkdir -p $_mnt/$_arg
                        	smbmount //$_server/$_arg $_mnt/$_arg -o $_opt
                        fi

                done
}
connect_to_shares
