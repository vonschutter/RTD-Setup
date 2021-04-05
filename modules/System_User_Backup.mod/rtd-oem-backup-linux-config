#!/bin/bash
PUBLICATION="RTD Simple User Configuration Backup Tool"
VERSION="1.00"
#
#::             RTD Ubuntu + derivatives backup script
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Author:   	SLS 
#::
#::
#::	Purpose: The purpose of the script is to backup a users setings 
#::              and dokuments to some useful location.
#::
#:: This system configuration and installation script was originally developed
#:: for RuntimeData, a small OEM in Buffalo Center, IA. 
#::
#:: RTD admin scrips are placed in /opt/rtd/scripts. This configuration script is mainly built to use 
#:: functions in _rtd_functions and _rtd_recipies. 
#::       _rtd_functions -- contain usefull admin functions for scripts, such as "how to install software" on different systems. 
#::       
#::
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
# You may comment out or edit items as you deem necessary.
# Ensure that the  RTD Functions are available and load them... 
# This contains most of the intelligence used to perform this systems
# maintenance. 
# 
# the RTD Functions contain useful task functions (example): 
#  -  check_dependencies
#  -  ensure_admin
#
_FILE=_rtd_functions
_RTD_S_HOME=/opt/rtd/scripts
unset rtd_oem_user_backup_destination
source $_RTD_S_HOME/$_FILE


# Set the background tilte:
BACKTITLE="$PUBLICATION"

# Set the options to appear in the menu as choices:
option_1="Gnome Desktop Setings"
option_2="Gnome Credentials Manager"
option_3="Remmina Configuration" 
option_4="Users Private Themes" 
option_5="Users Private Icons" 
option_6="Users Private Fonts " 
option_7="Users Private Documents" 
option_8="Users Private Pictures" 
option_9="Firefox Settings" 
option_10="Chrome Settings"  
option_11="All VirtualBox VMs" 
option_12="Teamviewer Configuration" 
option_13="Backup entire HOME folder"
option_14="Backup All Virtual Machines (KVM)"
                   




#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Functions                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#



# Function to request an encryption phrase. 
# This prase will be used to encrypt the compressed archives. 
zenity_ask_for_encryption_pass_phrase () {
	check_dependencies zenity
    	passtoken=$(zenity --title "Encryption Password" --password ) 
    	if [[ -z "$passtoken" ]]; then
                zenity --warning --text="Your settings likely contain sensitive information and should be encrypted! Please set a pass phrase"
		zenity_ask_for_encryption_pass_phrase
        fi
}



# Function to display the backup otions above. This is all done in a bit of a 
# round about way... but the idea is to prepare this setup to be flexible
# for the future so that you only have one place to list the option while
# more than one gui toolkit (dialog, zenity, whiptail) depending on your environment.
zenity_show_list_of_user_backup_choices () {
        cmd=( zenity  --list  --width=800 --height=400 --text "Please Select Whant to Backup" --title "$BACKTITLE" --checklist  --column "ON/OFF" --column "What to backup" --separator "," )
        zstatus=FALSE
        options=(    $zstatus "$option_1"
                     $zstatus "$option_2"
                     $zstatus "$option_3"
                     $zstatus "$option_4"
                     $zstatus "$option_5"
                     $zstatus "$option_6"
                     $zstatus "$option_7"
                     $zstatus "$option_8"
                     $zstatus "$option_9"
                     $zstatus "$option_10"
                     $zstatus "$option_11"
                     $zstatus "$option_12"
		     $zstatus "$option_13"
		     $zstatus "$option_14"
                   )

       choices=$("${cmd[@]}" "${options[@]}" )
}




# Simple function to display a infromational notice when the tool is envoked. 
rtd_oem_user_backup_info_notice() {

	zenity --info --width=800 --height=400 --text="

The RTD User Backup tool is a simple tool to allow anyone to backup important files and/or the entire home folder to an external USB drive as a backup ahead of re-installing a PC from scratch. 

It is highly recommended to encrypt all content so that is cannot easily be stolen. Do remember the password or you will never be able to access the backed-up content ever again. 

You will need the following: 
1 - An external drive
2 - A good password

The RTD Backup tool will encrypt, compress and save all the information in the location provided. 
	"
}



# Dialog to request the destination of where to store the compressed and encrypted archive. 
rtd_oem_request_user_backup_destination() {
	if [[ -z "$rtd_oem_user_backup_destination" ]]; then
		export rtd_oem_user_backup_destination=$( zenity --width=800 --height=400 --text "$BACKTITLE" --file-selection --directory  )
	elif [[ -n "$string" ]]; then
		echo "Saving Backup to: $rtd_oem_user_backup_destination"
	fi	
}
	


# Notify end user thes backup tasks are complete.
rtd_oem_user_backup_info_notice_complete() { 
	zenity --info --width=800 --height=400 --text="
Backup is complete. Please revise the list below. 

Backup archive(s) saved to:
$rtd_oem_user_backup_destination

Archives:
$(ls $rtd_oem_user_backup_destination/*.7z )
"
}



# Cleanup any potential junk left in the environment.
rtd_oem_cleanup() {

	unset rtd_oem_user_backup_destination
	unset passtoken
}


	
# Function to execute the given backup and encryption task. Levels of compression and 
# other option may be set in the seting section of this script (tool)
rtd_user_bak () {
	rtd_oem_request_user_backup_destination 
	echo ... > $rtd_oem_user_backup_destination/flg 
	if [[ -e $rtd_oem_user_backup_destination/flg ]]; then
		rm $rtd_oem_user_backup_destination/flg
		if [[ -d $2 ]]; then 
			7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -p$passtoken $rtd_oem_user_backup_destination/`whoami`-"$1"-`date -u --iso-8601`.7z "${@:2}"
		else 
			echo "Backup source $2 does not exist..."
		fi 
	else 
		zenity --info --width=800 --height=400 --text="$rtd_oem_user_backup_destination is not writable! Plese select another destination."
		rtd_oem_request_user_backup_destination
	fi
}	


		
# Function to do what the choices instruct. We read the output from 
# the choices and execute commands that accomplish the task requested. 
do_instructions_from_choices (){
        IFS=$','
	for choice in $choices
	do
		case $choice in
	        "$option_1") rtd_user_bak "$option_1" ~/Templates ;;
		"$option_2") rtd_user_bak "$option_2" ~/Templates ;;
		"$option_3") rtd_user_bak "$option_3" ~/.local/share/remmina ~/.config/remmina	;;
		"$option_4") rtd_user_bak "$option_4" ~/.themes ;;
		"$option_5") rtd_user_bak "$option_5" ~/.icons ;;
		"$option_6") rtd_user_bak "$option_6" ~/.fonts	;;
		"$option_7") rtd_user_bak "$option_7" ~/Documents ;;
		"$option_8") rtd_user_bak "$option_8" ~/Pictures ;;
		"$option_9") rtd_user_bak "$option_9" ~/Templates ;;
		"$option_10") rtd_user_bak "$option_10" ~/.config/google-chrome/Default/Preferences ;;
		"$option_11") rtd_user_bak "$option_11" "~/VirtualBox VM's" ;;
		"$option_12") rtd_user_bak "$option_12" ~/.config/teamviewer ;;
		"$option_13") rtd_user_bak "$option_13" $HOME ;;
		"$option_14")
			echo $passtoken |sudo -S chmod 777 -R /var/lib/libvirt
			rtd_user_bak "$option_14" /var/lib/libvirt
			echo $passtoken |sudo -S  chmod 750 -R /var/lib/libvirt
			echo $passtoken |sudo -S  chown -R libvirt-qemu /var/lib/libvirt 
		;;
		esac
	done  
}



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Sript Flow Control              ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#
# Software and configuration selections dialog. This will present a number of OEM defaults
# and other preferences that can be added to a system at will. To remove software it is 
# recommended to use the native software tool (Gnome Software, Yast, or Discover).
#
# Option defaults may be set to "on" or "off"

# "dialog" will be used to request interactive configuration...
# Ensure that it is available: 
trap "passtoken=nonsense" 0 1 2 5 15
rtd_oem_user_backup_info_notice
zenity_ask_for_encryption_pass_phrase
zenity_show_list_of_user_backup_choices
do_instructions_from_choices 
rtd_oem_user_backup_info_notice_complete




#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Finalize.....                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rtd_oem_cleanup
exit



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          deprecated...                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


function fallback_show_list_of_user_backup_choices () {

        check_dependencies whiptail
        cmd=(whiptail --separate-output --backtitle "$BACKTITLE" --title "What to backup" --checklist "Please Select what you want to backup below:" 22 85 18 )
        optionlist=( 1 "Gnome Setings" ON 
                     2 "Gnome Credentials Manager" ON 
                     3 "Remmina Configuration" ON 
                     4 "Users Private Themes" ON 
                     5 "Users Private Icons" ON 
                     6 "Users Private Fonts " ON 
                     7 "Users Private Documents" ON 
                     8 "Users Private Pictures" ON 
                     9 "Firefox Settings" ON 
                     10 "Chrome Settings"  ON 
                     11 "VirtualBox VM's (may be really large files and take time)" ON 
                     12 "Teamviewer Configuration" ON 
		     12 "Entire HOME Folder" ON 
                     )
}















