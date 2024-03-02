# :: --    --
# ::                        Windows PowerShell Script
# ::
# :                         A D M I N   S C R I P T
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# ::::::::::::::::::::::::::::::::::::::// OEM System Configuration Script //:::::::::::::::::::::::::// Windows//::::::::
# ::
# :: Author:			Vonschutter
# :: Version: 			1.0
# ::
# ::
# :: Purpose: 	The purpose of the script is to:
# ::		- Download KMS activation script from 3rd party
# ::		- Run KMS activation for Windows and Office 180 day trial
# ::
## ::
# :: Background: This script is shared in the hopes that someone will find it usefull. To encourage sharing changes
# :: 		 back to the source this script is released under the GPL v3. (see source location for details)
# ::		 https://github.com/vonschutter/RTD-Setup/raw/master/LICENSE.md
# ::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


irm https://massgrave.dev/get | iex
