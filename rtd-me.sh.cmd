#!/bin/bash

:<<"::CMDLITERAL"
cls
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL

echo				-	RTD System System Managment Bootstrap Script      -
#::
#::
#:: 						Shell Script Section
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Author(s):	SLS, KLS, NB.  Buffalo Center, IA & Avarua, Cook Islands
#:: Version:	1.07
#::
#::
#:: Purpose: 	The purpose of the script is to decide what scripts to download based
#::          	on the host OS found; works with both Windows, MAC and Linux systems.
#::		The focus of this script is to be compatible enough that it could be run on any
#::		system and compete it's job. In this case it is simply to identify the OS
#::		and get the appropriate script files to run on the system in question;
#::		In its original configuration this bootstrap script was used to install and
#::		configure software appropriate for the system in question. It accomplishes this
#::		by using the idiosyncrasies of the default scripting languages found in
#::		the most popular operating systems around *NIX (MAC, Linux, BSD etc.) and
#::		CMD (Windows NT, 2000, 2003, XP, Vista, 8, and 10).
#::
#:: NOTE:	To redirect this script to your own repository, simply rename the first 3 letters
#::		to match the name of your repository ("TLA"-Setup), and set the _GIT_PROFILE variable
#::		to the repo user or org to override the default (git username)...
#::
#:: Background: This system configuration and installation script was originally developed
#:: 		for RuntimeData, a small OEM in Buffalo Center, IA. The purpose of the script
#:: 		was to install and/or configure Ubuntu, Zorin, or Microsoft OS PC's. This OEM and store nolonger
#:: 		exists as its owner has passed away. This script is shared in the hopes that
#:: 		someone will find it usefull.
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	NOTE:	This terminal program is written and documented to a very high degree. The reason for doing this is that
#		these scripts are seldom changed and when they are, it is usefull to be able to understand why and how
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
#	  _rtd_functions -- contain usefull admin functions for scripts, such as "how to install software" on different systems.
#	  _rtd_recipies  -- contain software installation and configuration "recipies".
#	Scripts may also be stand-alone if there is a reason for this.
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
#
#				OUTPUT REDIRECTION TABLE
#
#		  || visible in terminal ||   visible in file   || existing
#	  Syntax  ||  StdOut  |  StdErr  ||  StdOut  |  StdErr  ||   file
#	==========++==========+==========++==========+==========++===========
#	    >     ||    no    |   yes    ||   yes    |    no    || overwrite
#	    >>    ||    no    |   yes    ||   yes    |    no    ||  append
#	          ||          |          ||          |          ||
#	   2>     ||   yes    |    no    ||    no    |   yes    || overwrite
#	   2>>    ||   yes    |    no    ||    no    |   yes    ||  append
#	          ||          |          ||          |          ||
#	   &>     ||    no    |    no    ||   yes    |   yes    || overwrite
#	   &>>    ||    no    |    no    ||   yes    |   yes    ||  append
#	          ||          |          ||          |          ||
#	 | tee    ||   yes    |   yes    ||   yes    |    no    || overwrite
#	 | tee -a ||   yes    |   yes    ||   yes    |    no    ||  append
#	          ||          |          ||          |          ||
#	 n.e. (*) ||   yes    |   yes    ||    no    |   yes    || overwrite
#	 n.e. (*) ||   yes    |   yes    ||    no    |   yes    ||  append
#	          ||          |          ||          |          ||
#	|& tee    ||   yes    |   yes    ||   yes    |   yes    || overwrite
#	|& tee -a ||   yes    |   yes    ||   yes    |   yes    ||  append
#
#	The best solution is to redirect at the "wrapper" layer; a.k.a. the script that loads these functions
#	and executes them. Simply use the "source" statement to pull in the "_rtd_library" and it will do the rest:
#	you can now simply name each function herein that you wish to have installed on a wide range of distributions.
#
#	Our scripts are also structured in to three major sections: "settings", "functions", and "execute".
#	Settings, contain configurable options for the script. Functions, contain all functions. Execute,
#	contains all the actual logic and control of the script.
#
#	Convention: All exported (global) variables are UPPER case, all temp,local or otherwise are lower case.
#		    Also, all exported variables begin with "_" to avoid any conflict with system or shell variables.

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Variables that govern the behavior or the script and location of files are
# set here. There should be no reason to change any of this abcent strong preferences.
printf '\n'

YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"

# Ensure administrative privileges.
[ "$UID" -eq 0 ] || echo -e $YELLOW "This script needs administrative access..." $NO_COLOR
[ "$UID" -eq 0 ] || exec sudo -E bash "$0" "$@"

# Put a convenient link to the logs where logs are normally found...
# capture the 3 first letters as org TLA (Three Letter Acronym)
export _SCRIPTNAME=$(basename $0)
export _TLA=${_SCRIPTNAME:0:3}
export _LOG_DIR=/var/log/${_TLA}
mkdir -p ${_LOG_DIR}

# Set the GIT profile name to be used if not set elsewhere:
export _GIT_PROFILE="${_GIT_PROFILE:-vonschutter}"

# Location of base administrative scripts and command-lets to get.
_git_src_url=https://github.com/${_GIT_PROFILE}/${_TLA^^}-Setup.git

# Determine log file names for this session
export _ERRLOGFILE=${_LOG_DIR}/$(date +%Y-%m-%d-%H-%M-%S-%s)-oem-setup-error.log
export _LOGFILE=${_LOG_DIR}/$(date +%Y-%m-%d-%H-%M-%S-%s)-oem-setup.log
export _STATUSLOG=${_LOG_DIR}/$(date +%Y-%m-%d-%H-%M-%S-%s)-oem-setup-status.log


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Execute tasks                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#:: Given that Bash or other Shell environment has been detected and the POSIX chell portion of this script is executed,
#:: the second stage script must be downloaded from an online location. Depending on the distribution of OS
#:: there are different methods available to get and run remote files.
#::
#:: Table of evaluating family of OS and executing the appropriate action fiven the OS found.
#:: In this case it is easier to manage a straight table than a for loop or array:


if echo "$OSTYPE" |grep "linux" ; then
	echo "Linux OS Found: Attempting to get instructions for Linux..."
	echo executing $0 >> ${_LOGFILE}
	for d in git zip ; do 
		if ! hash ${d} &>> ${_LOGFILE} ; then
			for pkgmgr in apt yum dnf zypper ; do hash ${pkgmgr} && ${pkgmgr} install -y ${d} | tee ${_LOGFILE} ; done
		fi
	done
	git clone --depth=1 ${_git_src_url} /opt/${_TLA,,}.tmp | tee ${_LOGFILE}
		if [ $? -eq 0 ]
		then
			echo "Instructions successfully retrieved..."
			if [[ -d /opt/${_TLA,,}  ]] ; then
				mv /opt/${_TLA,,} ${_BackupFolderName:="/opt/${_TLA,,}.$(date +%Y-%m-%d-%H-%M-%S-%s).bakup"}
				zip -m -r -5 ${_BackupFolderName}.zip  ${_BackupFolderName}
				rm -r ${_BackupFolderName}
			fi
			mv /opt/${_TLA,,}.tmp /opt/${_TLA,,} ; rm -rf /opt/${_TLA,,}/.git
			source /opt/${_TLA,,}/core/_rtd_library
			oem::register_all_tools
			ln -s -f ${_LOG_DIR} -T ${_OEM_DIR}/log
			bash ${_OEM_DIR}/core/rtd-oem-linux-config.sh ${@}
		else
			echo "Failed to retrieve instructions correctly! "
			echo "Suggestion: check write permission in "/opt" or internet connectivity."
			exit 1
		fi
        exit $?
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Mac OSX is currently not supported..."
elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "CYGWIN is currently unsupported..."
elif [[ "$OSTYPE" == "msys" ]]; then
        echo "Lightweight shell is currently unsupported... "
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "Free BSD is currently unsupported... "
else
       echo "This system is Unknown to this script"
fi
exit $?


# -----------------------------------------------------------------------------------------------------------------------
# Anything after this exit statment below will be dangerous and meaningless
# command syntax to POSIX based systems...
# Make sure to exit no matter what...
exit $?
:CMDSCRIPT
@echo off
echo			-	RTD System System Managment Bootstrap Script      -
::
::
::					Windows CMD Shell Script Section
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Variables and Assignments
:: Passed From CONSOLE!
::		%0 		-> %Scriptname%
:: 		Common TS
::		%DEBUG% 	-> 1 value to turn on tracing
::		%ECHO% 		-> On Value to turn on echo
::		%RET% 		-> Argument Passing Value
::
:: 	Please list command files to be run here in the following format:
::
:: 	:TITLE
:: 	Description of the pupose of called command file.
:: 	call <path>\command.cmd or command...
::
::
:: The preferred method of coding NT Shell well is per the Tim Hill Windows NT Shell Scripting book, ISBN: 1-57878-047-7
:: This is to ensure a secure and controlled way to execute components in the script. This may be an old way
:: but it is relible and it works in all versions of Windows starting with Windows NT. However, newer more powerfull
:: scripting languages are available. These should be used where appropriate in the stage 2 of this process.
:: This bootstrap sctipt is intended for compatibility and this section therefore focuses on Windows CMD as this
:: works in all earlier 32 and 64 bit versions of Windows.
::
:: Example 1
::
:: for %%d in (%_dependencies%) do (call :VfyPath %%d)
::	if not {%RET%}=={0} (set _ERRMSG="An unrecoverable error has occured..." & call :DispErr !
::			) else (
::			goto MAIN)
:: endlocal & goto eof
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:INIT
	:::::::::::::::::::::::::::::::::::::::::::::::::::
	::	Script startup components; tasks that always
	::	need to be done when the initializes.
	::
	ECHO Welcome to %COMSPEC%
	ECHO This is a windows script!
	setlocal &  pushd %~dp0
	:: %debug%
	color 17
	title RTD OEM Launcher

:SETINGS
	::::::::::::::::::::::::::::::::::::::::::::::::::::::
	::  ***             Settings               ***      ::
	::::::::::::::::::::::::::::::::::::::::::::::::::::::
	::
	mkdir c:\rtd\temp
	set temp=c:\rtd\temp
	mkdir c:\rtd\log
	set _LOGDIR=c:\rtd\log
	md %_LOGDIR%
	set _STAGE2LOC=https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/
	set _STAGE2FILE=rtd-oem-win10-config.ps1
	echo Stage 2 file is located at:
	echo %_STAGE2LOC%\%_STAGE2FILE%


:GetInterestingThigsToDoOnThisSystem
	:: Given that Microsoft Windows has been detected and the CMD chell portion of this script is executed,
	:: the second stage script must be downloaded from an online location. Depending on the version of Windows
	:: there are different methods available to get and run remote files. All versions of Windows do not neccesarily
	:: support powershell scripting. Therefore the base of this activity is coded in simple command CMD.EXE shell scripting
	::
	:: Table of evaluating verson of Windows and calling the appropriate action given the version of Windows found.
	:: In this case it is easier to manage a straight table than a for loop or array:

	:: DOS Based versions of Windows:
	ver | find "4.0" > %_LOGDIR%\%0.log && goto BAT1 	rem Windows 95
	ver | find "4.10" > %_LOGDIR%\%0.log && goto BAT1	rem Windows 98
	ver | find "4.90" > %_LOGDIR%\%0.log && goto BAT1	rem Windows ME

	:: Windows 32 and 64 Bit versions:
	ver | find "NT 4.0" > %_LOGDIR%\%0.log && call :CMD1 Windows NT 4.0
	ver | find "5.0" > %_LOGDIR%\%0.log && call :CMD1 Windows 2000
	ver | find "5.1" > %_LOGDIR%\%0.log && call :CMD1 Windows XP
	ver | find "5.2" > %_LOGDIR%\%0.log && call :CMD1 Windows XP 64 Bit
	ver | find "6.0" > %_LOGDIR%\%0.log && call :DispErr Vista is not supported!!!
	ver | find "6.1" > %_LOGDIR%\%0.log && call :PS1 Windows 7
	ver | find "6.2" > %_LOGDIR%\%0.log && call :PS2 Windows 8
	ver | find "6.3" > %_LOGDIR%\%0.log && call :PS2 Windows 8
	ver | find "6.3" > %_LOGDIR%\%0.log && call :PS2 Windows 8
	ver | find "10.0" > %_LOGDIR%\%0.log && call :PS2 Windows 10

	:: Windows Server OS Versions:
	ver | find "NT 6.2" > %_LOGDIR%\%0.log && call :PS2 Windows Server 2012
	ver | find "NT 6.3" > %_LOGDIR%\%0.log && call :PS2 Windows Server 2012 R2
	ver | find "NT 10.0" > %_LOGDIR%\%0.log && call :PS2 Windows Server 2016 and up...

	goto end


:PS1
	:: Procedure to get the second stage in Windows 7. Windows 7, by default has a different version of
	:: PowerShell installed. Therefore a slightly different syntax must be used.
	:: get stage 2 and run it...
	echo Found %*
	echo Fetching %_STAGE2FILE%...
	echo Please wait...
	powershell -Command "(New-Object Net.WebClient).DownloadFile('%_STAGE2LOC%\%_STAGE2FILE%', '%_STAGE2FILE%')"
	powershell -Command "iwr -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1 | iex"
	powershell -ExecutionPolicy UnRestricted -File .\%_STAGE2FILE%
	goto end


:PS2
	:: Procedure to get the second stage configuration script in all versions of Windows after 7.
	:: These versions of Windows have a more modern version of PowerShell.
	:: get stage 2 and run it...
	echo Found %*
	echo Fetching %_STAGE2FILE%...
	echo Please wait...
	powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-WebRequest %_STAGE2LOC%\%_STAGE2FILE% -OutFile %_STAGE2FILE%"
	powershell -Command "iwr -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1 | iex"
	powershell -ExecutionPolicy UnRestricted -File .\%_STAGE2FILE%
	goto end



:CMD1
	:: Pre windows 7 instructions go here...
	:: Windows NT, XP, and 2000 etc. do not have powershell and must find a different way to
	:: fetch a script over the internet and execute it.
	echo Detected %* ...
	echo executing PRE Windows 7 instructions...
	echo However, no instructions for Windows NT or 2000 are avaliable.
	goto end


:BAT1
	:: DOS Based instructions go here ...
	:: Windows 3.11 - ME etc. do not have powershell and must find a different way to
	:: fetch a script over the internet and execute it.
	echo Detected an ancient Microsoft OS...
	echo Executing DOS Based instructions...
	echo However, nothing for this has been created as DOS, Windows 3.11, 95, 98, ME are too ancient!
	goto END


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::                                          ::::::::::::::::::::::
::::::::::::::            ERROR handling Below          ::::::::::::::::::::::
::::::::::::::                                          ::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:DispErr
	set _ERRMSG=%*
	@title %0 -- !!%_ERRMSG%!!
	echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo ::                            Message                                          ::
	echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo.
	echo.
	echo        %_ERRMSG%
	echo        Presently I know what to do for Linux, and Windows 7 and beyond...
	echo.
	echo ::                                                                             ::
	echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto eof



:end
:EOF
