#!/usr/bin/env bash
#				-	RTD System System Managment Bootstrap Script      -
#
#::::::::::::::::::::::::::::::::::::::::::::: HEADER DO NOT REMOVE :::::::::::::::::::::::::::::::::::::::::::::::::::::
:<<"::CMDLITERAL"
cls
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#::::::::::::::::::::::::::::::::::::::::::::: HEADER DO NOT REMOVE :::::::::::::::::::::::::::::::::::::::::::::::::::::
#::
#:: 						Shell Script Section
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:: Author(s):	SLS, KLS, NB.  Buffalo Center, IA & Avarua, Cook Islands
Version="1.08.2024-06-01"
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
#:: 		was to install and/or configure Ubuntu, Zorin, or Microsoft OS PC's. This OEM and store no longer
#:: 		exists as its owner has passed away. This script is shared in the hopes that
#:: 		someone will find it useful.
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	NOTE:	This terminal program is written and documented to a very high degree. The reason for doing this is that
#		these scripts are seldom changed and when they are, it is useful to be able to understand why and how
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
#	functions in _rtd_functions and _rtd_recipes.
#	  _rtd_functions -- contain useful admin functions for scripts, such as "how to install software" on different systems.
#	  _rtd_recipes  -- contain software installation and configuration "recipes".
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
#	We also like to log all activity, and to echo status output to the screen in a friendly way. To accomplish this,
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
# set here. There should be no reason to change any of this absent strong preferences.
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"
export _SCRIPTNAME="$(basename "$0")"
export _TLA="${_SCRIPTNAME:0:3}"
export _TLA_UPPER="$(printf '%s' "${_TLA}" | tr '[:lower:]' '[:upper:]')"
export _TLA_LOWER="$(printf '%s' "${_TLA}" | tr '[:upper:]' '[:lower:]')"
export _GIT_PROFILE="${_GIT_PROFILE:-vonschutter}"

# Shared repository and log settings.
_RTD_SETUP_GIT_URL="https://github.com/${_GIT_PROFILE}/${_TLA_UPPER}-Setup.git"
_RTD_SETUP_RAW_URL="https://raw.githubusercontent.com/${_GIT_PROFILE}/${_TLA_UPPER}-Setup/main"
export _LOG_DIR="/var/log/${_TLA_LOWER}"
export _LOGFILE="${_LOG_DIR}/${_SCRIPTNAME}-$(date +%Y-%m-%d)-oem.log"

# Shared POSIX config paths. Linux, macOS, BSD, and similar systems use /opt.
_CONFIG_DIR="/opt/${_TLA_LOWER}"
_CONFIG_TMP_DIR="${_CONFIG_DIR}.tmp"
_CONFIG_CORE_DIR="${_CONFIG_DIR}/core"
_CONFIG_LOG_LINK="${_CONFIG_DIR}/log"

# POSIX stage-two script names.
_LINUX_SCRIPT="rtd-oem-linux-config.sh"
_MAC_SCRIPT="rtd-oem-macos-config.sh"

# Shared privilege helper. macOS keeps the bootstrap running as the logged-in
# user and uses sudo only for install/update operations. Linux re-enters this
# script once as root so SUDO_USER is available to the stage-two scripts.
_SUDO=()
if [ "$UID" -ne 0 ]; then
	printf "%b\n" "${YELLOW}This script needs administrative access for bootstrap operations.${NO_COLOR}"
	_SUDO=(sudo)
	"${_SUDO[@]}" -v || exit 1
fi

"${_SUDO[@]}" mkdir -p "${_LOG_DIR}" 2>/dev/null || true




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


if [[ "$OSTYPE" == *"linux"* ]]; then
	if [ "$UID" -ne 0 ]; then
		exec "${_SUDO[@]}" -E bash "$0" "$@"
	fi
	{
	printf "🌎 Linux OS Found: Attempting to get instructions for Linux: \n executing $0"
	printf "📦 Verifying that the required software to continue is available and installing if not there..."
	for d in git zip; do 
		if ! command -v "$d" &>/dev/null; then
			for pkgmgr in apt yum dnf zypper; do
				if hash "${pkgmgr}" &>/dev/null; then
				"${pkgmgr}" install -y "$d" && break
				fi
			done
		fi
	done
	
	rm -rf "${_CONFIG_TMP_DIR}"
	if git clone --depth=1 "${_RTD_SETUP_GIT_URL}" "${_CONFIG_TMP_DIR}" ; then
		printf "✅ Instructions successfully retrieved..."
		if [[ -d "${_CONFIG_DIR}"  ]] ; then
			_BackupFolderName="${_CONFIG_DIR}.$(date +%Y-%m-%d-%H-%M-%S-%s).bakup"
			mv "${_CONFIG_DIR}" "${_BackupFolderName}"
			zip -m -r -5 "${_BackupFolderName}.zip" "${_BackupFolderName}"
			rm -rf "${_BackupFolderName}"
		fi
		mv "${_CONFIG_TMP_DIR}" "${_CONFIG_DIR}" ; rm -rf "${_CONFIG_DIR}/.git"
			if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
				echo "ERROR: RTD _rtd_library requires Bash 4.4 or newer. Current shell: Bash ${BASH_VERSION}." >&2
				exit 1
			fi
			source "${_CONFIG_CORE_DIR}/_rtd_library"
		oem::register_all_tools
		ln -s -f "${_LOG_DIR}" -T "${_CONFIG_LOG_LINK}"
		bash "${_CONFIG_CORE_DIR}/${_LINUX_SCRIPT}" "$@"
	else
		printf "💥 Failed to retrieve instructions correctly! "
		exit 1
	fi
	} 2>&1 | tee -a "${_LOGFILE}"
	exit $?
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Mac OSX is currently not fully supported by ${_SCRIPTNAME} version ${Version}... however, I will attempt to get the appropriate script for this system and run it..."
	read -n 1 -s -r -p "Press any key to continue... or CTRL+C to exit"
	
	if ! "${_SUDO[@]}" mkdir -p "${_CONFIG_CORE_DIR}" ; then
		echo "Failed to create ${_CONFIG_CORE_DIR}."
		exit 1
	fi
	
	"${_SUDO[@]}" rm -f "${_CONFIG_CORE_DIR}/${_MAC_SCRIPT}"
	
	if ! "${_SUDO[@]}" curl -fsSL "${_RTD_SETUP_RAW_URL}/core/${_MAC_SCRIPT}" -o "${_CONFIG_CORE_DIR}/${_MAC_SCRIPT}" ; then
		echo "Failed to download ${_RTD_SETUP_RAW_URL}/core/${_MAC_SCRIPT}"
		exit 1
	fi

	if ! head -n 1 "${_CONFIG_CORE_DIR}/${_MAC_SCRIPT}" | grep -Eq '^#!.*(ba)?sh' ; then
		echo "Downloaded macOS configuration script does not look executable. Aborting."
		exit 1
	fi

	"${_SUDO[@]}" chmod 0755 "${_CONFIG_CORE_DIR}/${_MAC_SCRIPT}" || { echo "Failed to make ${_CONFIG_CORE_DIR}/${_MAC_SCRIPT} executable."; exit 1; }
	RTD_MACOS_SETUP_RAW_URL="${_RTD_SETUP_RAW_URL}" bash "${_CONFIG_CORE_DIR}/${_MAC_SCRIPT}" "$@"
	exit $?
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
# Anything after this exit statement below will be dangerous and meaningless
# command syntax to POSIX based systems...
# Make sure to exit no matter what...
# -----------------------------------------------------------------------------------------------------------------------
:CMDSCRIPT
@title			-	RTD System System Management Bootstrap Script      -
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
:: 	Description of the purpose of called command file.
:: 	call <path>\command.cmd or command...
::
::
:: The preferred method of coding NT Shell well is per the Tim Hill Windows NT Shell Scripting book, ISBN: 1-57878-047-7
:: This is to ensure a secure and controlled way to execute components in the script. This may be an old way
:: but it is reliable and it works in all versions of Windows starting with Windows NT. However, newer more powerful
:: scripting languages are available. These should be used where appropriate in the stage 2 of this process.
:: This bootstrap script is intended for compatibility and this section therefore focuses on Windows CMD as this
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
        @echo off
	echo Welcome to %COMSPEC%
	echo This is a windows script!
	setlocal &  pushd %~dp0
	:: %debug%

:SETINGS
	::::::::::::::::::::::::::::::::::::::::::::::::::::::
	::  ***             Settings               ***      ::
	::::::::::::::::::::::::::::::::::::::::::::::::::::::
	::

	:: gather some info... (BETA)
	setlocal EnableDelayedExpansion
	set "ScriptName=%~nx0"
	set "ScriptPath=%~dp0"
	set "_tla=%ScriptName:~0,3%"
	set "lowercase=abcdefghijklmnopqrstuvwxyz"
	set "uppercase=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	set "Result="
	for /L %%i in (0,1,2) do (
		set "char=!_tla:~%%i,1!"
		for /L %%j in (0,1,25) do (
			if "!char!"=="!lowercase:~%%j,1!" set "char=!uppercase:~%%j,1!"
		)
		set "Result=!Result!!char!"
	)
	set _TLA=%Result%
	set _TLA=RTD
	set TEMP=C:\%_TLA%\temp
	set LOG_DIR=C:\%_TLA%\log
	set WALLPAPER_DIR=C:\%_TLA%\wallpaper
	set CACHE_DIR=C:\%_TLA%\cache
	set CORE_DIR=C:\%_TLA%\core
        set WALLPAPER_URL=https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/wallpaper/Wayland.jpg
        set VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-guest-tools.exe
	set _STAGE2LOC=https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/
	set _STAGE2FILE=rtd-oem-win10-config.ps1
	set _WINDOWS_BUILD=0
	for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::OSVersion.Version.Build" 2^>nul`) do set _WINDOWS_BUILD=%%i
	if %_WINDOWS_BUILD% GEQ 22000 set _STAGE2FILE=rtd-oem-win11-config.ps1

	md %TEMP%
	md %LOG_DIR%
	md %WALLPAPER_DIR%
        md %CACHE_DIR%
	md %CORE_DIR%

	@title "Stage 2 file is located at: %_STAGE2LOC%\%_STAGE2FILE%"

        set >>%LOG_DIR%\%_TLA%.log
        ver >>%LOG_DIR%\%_TLA%.log
    
:GetInterestingThigsToDoOnThisSystem
	:: Given that Microsoft Windows has been detected and the CMD shell portion of this script is executed,
	:: the second stage script must be downloaded from an online location. Depending on the version of windows
	:: there are different methods available to get and run remote files. All versions of windows do not necessarily
	:: support power-shell scripting. Therefore the base of this activity is coded in simple command CMD.EXE shell scripting
	::
	:: Table of evaluating version of windows and calling the appropriate action given the version of windows found.
	:: In this case it is easier to manage a straight table than a for loop or array:

	:: DOS Based versions of Windows:
	:: ver | find "4.0" > nul && goto CMD1 	rem Windows 95
	:: ver | find "4.10" > nul && goto CMD1 rem Windows 98
	:: ver | find "4.90" > nul && goto CMD1	rem Windows ME

	:: Windows 32 and 64 Bit versions:
	ver | find "NT 4.0" > nul && call :CMD1 Windows NT 4.0
	ver | find "5.0" > nul && call :CMD1 Windows 2000
	ver | find "5.1" > nul && call :CMD1 Windows XP
	ver | find "5.2" > nul && call :CMD1 Windows XP 64 Bit
	ver | find "6.0" > nul && call :DispErr Vista is not supported!!!
	ver | find "6.1" > nul && call :PS1 Windows 7
	ver | find "6.2" > nul && call :PS2 Windows 8
	ver | find "6.3" > nul && call :PS2 Windows 8
	ver | find "6.3" > nul && call :PS2 Windows 8
	ver | find "10.0" > nul && if %_WINDOWS_BUILD% GEQ 22000 (call :PS2 Windows 11) else (call :PS2 Windows 10)

	:: Windows Server OS Versions:
	ver | find "NT 6.2" > nul && call :PS2 Windows Server 2012
	ver | find "NT 6.3" > nul && call :PS2 Windows Server 2012 R2
	ver | find "NT 10.0" > nul && call :PS2 Windows Server 2016 and up...

	goto end


:PS1
	:: Procedure to get the second stage in Windows 7. Windows 7, by default has a different version of
	:: PowerShell installed. Therefore a slightly different syntax must be used.
	:: get stage 2 and run it...
	@title Found %* >>%LOG_DIR%\rtd.log
	echo Please wait...
	if exist A:\autounattend.xml copy /y A:\*.* %CORE_DIR%\

	@title: "Download and install virtio-drivers"
	powershell -Command "(New-Object Net.WebClient).DownloadFile('%VIRTIO_URL%', '%CACHE_DIR%\virtio-win-gt-x64.msi')"
        msiexec /i %CACHE_DIR%\virtio-win-gt-x64.msii /passive /norestart /l*v %LOG_DIR%\virtio_log.txt

        @title "Fetch Wallpaper for default background"
        powershell -Command "(New-Object Net.WebClient).DownloadFile('%WALLPAPER_URL%', '%WALLPAPER_DIR%\Default.jpg')"

	@title "Set network profiles to Private"
        powershell -Command "& {Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles' | ForEach-Object {Set-ItemProperty -Path $_.PSParentPath -Name 'Category' -Value 1}}"
 
	if exist %CORE_DIR%\%_STAGE2FILE% (
		echo File found locally...
		powershell -ExecutionPolicy UnRestricted -File %CORE_DIR%\%_STAGE2FILE%
		) else (
		echo Fetching %_STAGE2FILE% from the internet...
		powershell -Command "(New-Object Net.WebClient).DownloadFile('%_STAGE2LOC%/%_STAGE2FILE%', '%CACHE_DIR%\%_STAGE2FILE%')"
		powershell -ExecutionPolicy UnRestricted -File %CACHE_DIR%\%_STAGE2FILE%
	)

	if exist %CORE_DIR%\_Chris-Titus-Post-Windows-Install-App.ps1 (
		@title "CMD: _Chris-Titus-Post-Windows-Install-App.ps1 File found locally..."
		powershell -ExecutionPolicy UnRestricted -File %CORE_DIR%\_Chris-Titus-Post-Windows-Install-App.ps1
		) else (
		@title "CMD: Fetching _Chris-Titus-Post-Windows-Install-App.ps1 from the internet..."
		powershell -Command "iwr -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1 | iex"
	)
	goto end


:PS2
	:: Procedure to get the second stage configuration script in all version of windows after 7.
	:: These version of windows have a more modern version of PowerShell.
	:: get stage 2 and run it...
	echo Found %*
	if exist A:\autounattend.xml copy /y A:\*.* %CORE_DIR%\
	@title "POWERSHELL: seting NETWORK Config"
        powershell -Command "& {Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles' | ForEach-Object {Set-ItemProperty -Path $_.PSParentPath -Name 'Category' -Value 1}}"

        @title "POWERSHELL: Fetch Wallpaper for default background"
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-WebRequest %WALLPAPER_URL% -OutFile %WALLPAPER_DIR%\Default.jpg"

        @title "POWERSHELL: Download and install virtio-drivers"
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-WebRequest %VIRTIO_URL% -OutFile %CACHE_DIR%\virtio-win-guest-tools.exe"
        %CACHE_DIR%\virtio-win-guest-tools.exe /passive /norestart /log %LOG_DIR%\virtio_log.txt
    
	if exist %CORE_DIR%\%_STAGE2FILE% (
		@title "CMD: %_STAGE2FILE% File found locally..."
		powershell -ExecutionPolicy UnRestricted -File %CORE_DIR%\%_STAGE2FILE%
		) else (
		@title "CMD: Fetching %_STAGE2FILE% from the internet..."
		powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-WebRequest %_STAGE2LOC%/%_STAGE2FILE% -OutFile %CACHE_DIR%\%_STAGE2FILE%"
		powershell -ExecutionPolicy UnRestricted -File %CACHE_DIR%\%_STAGE2FILE%
	)

	if "%_STAGE2FILE%"=="rtd-oem-win11-config.ps1" goto end

	if exist %CORE_DIR%\_Chris-Titus-Post-Windows-Install-App.ps1 (
		@title "CMD: _Chris-Titus-Post-Windows-Install-App.ps1 File found locally..."
		powershell -ExecutionPolicy UnRestricted -File %CORE_DIR%\_Chris-Titus-Post-Windows-Install-App.ps1
		) else (
		@title "CMD: Fetching _Chris-Titus-Post-Windows-Install-App.ps1 from the internet..."
		powershell -Command "iwr -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1 | iex"
	)
	goto end


:CMD1
	:: Pre windows 7 instruction go here (except vista)...
	:: Windows NT, XP, and 2000 etc. do not have powershell and must find a different way to
	:: fetch a script over the internet and execute it.

	echo Detected %* ...
	echo executing PRE Windows 7 instructions...
	:: Assuming wget is in the path...
	wget -O %TEMP%\%_STAGE2FILE% %_STAGE2LOC%/%_STAGE2FILE%
	powershell -ExecutionPolicy UnRestricted -File %TEMP%\%_STAGE2FILE%

	goto end
endlocal

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
	pause
goto end

:end
