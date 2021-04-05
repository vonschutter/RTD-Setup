#!/bin/bash
#
#::             			A D M I N   C O M M A N D L E T
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::// Simple Admin Tool //::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#::
#:: Author:   	SLS
#:: Version 	1.00
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
        # Set library path if not defined:
        scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        rtd_library=${rtd_library:-"${scriptdir}/../../core/_rtd_library"}

        if [[ -f ${rtd_library} ]]; then
                source ${rtd_library}
        elif [[ ! -f ${rtd_library} ]]; then
                echo "RTD Functions not found... "
                echo "Trying to retrieve them..."
                wget https://github.com/vonschutter/RTD-Build/raw/master/System_Setup/_rtd_library
                source ./_rtd_library
        else
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
