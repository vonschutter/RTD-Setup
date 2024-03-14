:: --    --
::                        Windows CMD Script
::
::                         A D M I N   S C R I P T
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::// OEM System Configuration Script //:::::::::::::::::::::::::// Windows //:::::::
::
:: Author:			Vonschutter
:: Version: 		1.0
::
::
:: Purpose: 	The purpose of the script is to:
::		- Download KMS activation script from 3rd party
::		- Run KMS activation for Windows and Office 180 day trial
::
::
:: Background: This script is shared in the hopes that someone will find it usefull. To encourage sharing changes
:: 		 back to the source this script is released under the GPL v3. (see source location for details)
::		 https://github.com/vonschutter/RTD-Setup/raw/master/LICENSE.md
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:INIT
@echo off
@title "RTD Windows Configuration/Activation Menu"
set MAS_ACTIVATION_SCRIPT=_config_menu.ps1
set CTT_CONFIG_SCRIPT=_Chris-Titus-Post-Windows-Install-App.ps1
set CTT_URL=https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1
set MAS_URL=https://massgrave.dev/get
set RUN_DIR=%~dp0

pushd %~dp0
:MENU
color 1F
cls
echo :::::::::::::::::::// Windows Configuration Options //::::::::::::::::::::::::::
echo :::::::::::::::::::::::::::::// Menu //:::::::::::::::::::::::::::::::::::::::::
echo .  
echo .
echo . 1. CTT Menu (Windows Configuration)
echo . 2. MAS Menu (Windows Activation)
echo . 3. Exit
echo .
echo . NOTE: Local execution will be tried before fetching from the internet
echo .
echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set /p choice="                      Select an option (1-3): "
cls
if "%choice%"=="1" goto CTT
if "%choice%"=="2" goto MAS
if "%choice%"=="3" exit /b

goto MENU

:CTT
if exist %CTT_CONFIG_SCRIPT% (
    @title "CMD: Running %CTT_CONFIG_SCRIPT% locally"
    powershell -ExecutionPolicy UnRestricted -File %RUN_DIR%\%CTT_CONFIG_SCRIPT%
) else (
    @title "POWERSHELL: Running %CTT_URL% from the internet..."
    powershell -Command "iwr -useb %CTT_URL% | iex"
)
goto MENU

:MAS
if exist %RUN_DIR%\%MAS_ACTIVATION_SCRIPT% (
    @title "CMD: %MAS_ACTIVATION_SCRIPT% File found locally..."
    powershell -ExecutionPolicy UnRestricted -File %RUN_DIR%\%MAS_ACTIVATION_SCRIPT%
) else (
    @title "CMD: Running %MAS_URL% from the internet..."
    powershell -Command "irm %MAS_URL% | iex"
)
goto MENU