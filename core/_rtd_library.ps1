#::				R T D   F u n c t i o n   L i b r a r y
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Windows //::::::
#::	Author(s):   	SLS
#:: 	Version:	0.1
#::
#::
#::	Purpose:	To collect and enable the use of code snippets in other scripts.
#::			To document these thoroughly so that they may be useful for learning BASH.
#::	Usage: 		call this file as part of your script execution.
#::
#::	This script is shared in the hopes that
#::	someone will find it useful.
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::




function Set-DefaultBrowser
{
	<#
	(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\ftp\UserChoice').ProgId
	(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice').ProgId
	(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice').ProgId
	#>
	# Set-DefaultBrowser cr
	# Set-DefaultBrowser ff
	# Set-DefaultBrowser ie
	# Set-DefaultBrowser op
	# Set-DefaultBrowser sa
    param($defaultBrowser)

    $regKey      = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
    $regKeyFtp   = $regKey -f 'ftp'
    $regKeyHttp  = $regKey -f 'http'
    $regKeyHttps = $regKey -f 'https'

    switch -Regex ($defaultBrowser.ToLower())
    {
        # Internet Explorer
        'ie|internet|explorer' {
            Set-ItemProperty $regKeyFtp   -name ProgId IE.FTP
            Set-ItemProperty $regKeyHttp  -name ProgId IE.HTTP
            Set-ItemProperty $regKeyHttps -name ProgId IE.HTTPS
            break
        }
        # Firefox
        'ff|firefox' {
            Set-ItemProperty $regKeyFtp   -name ProgId FirefoxURL
            Set-ItemProperty $regKeyHttp  -name ProgId FirefoxURL
            Set-ItemProperty $regKeyHttps -name ProgId FirefoxURL
            break
        }
        # Google Chrome
        'cr|google|chrome' {
            Set-ItemProperty $regKeyFtp   -name ProgId ChromeHTML
            Set-ItemProperty $regKeyHttp  -name ProgId ChromeHTML
            Set-ItemProperty $regKeyHttps -name ProgId ChromeHTML
            break
        }
        # Safari
        'sa*|apple' {
            Set-ItemProperty $regKeyFtp   -name ProgId SafariURL
            Set-ItemProperty $regKeyHttp  -name ProgId SafariURL
            Set-ItemProperty $regKeyHttps -name ProgId SafariURL
            break
        }
        # Opera
        'op*' {
            Set-ItemProperty $regKeyFtp   -name ProgId Opera.Protocol
            Set-ItemProperty $regKeyHttp  -name ProgId Opera.Protocol
            Set-ItemProperty $regKeyHttps -name ProgId Opera.Protocol
            break
        }
    }
}


Function Restart {
	Write-Output "Restarting..."
	Restart-Computer

}


Function ChangeTheDefaultBrowser {
	param($defaultBrowser)

	$regKey = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
	$regKeyHttp = $regKey -f 'http'
	$regKeyHttps = $regKey -f 'https'

	switch -Regex ($defaultBrowser.ToLower()) {
	    # Brave Browser
	    # https://brave.com
	    'bb|brave' {
		Write-Output "`nChanging to Brave as the default browser $ThisUser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId BraveHTML
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash wlBpCu412iI=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId BraveHTML
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash 90HsnuS5S6M=
		break
	    }
	    # Google Chrome
	    # https://www.google.com/chrome/
	    'gc|google|chrome' {
		Write-Output "`nChanging to Chrome as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId ChromeHTML
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash k9Da/QqU74c=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId ChromeHTML
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash /vl+ronxuA4=
		break
	    }
	    # Chromium Browser
	    # https://www.chromium.org/getting-involved/download-chromium
	    'cb|chromium' {
		Write-Output "`nChanging to Chromium as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId ChromiumHTM
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash Kh+mL2zZByo=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId ChromiumHTM
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash EWoUqQneOv4=
		break
	    }
	    # Microsoft Edge
	    # https://www.microsoft.com/pt-br/windows/microsoft-edge
	    'me|edge' {
		Write-Output "`nChanging to Edge as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId AppX90nv6nhay5n6a98fnetv7tpk64pp35es
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash 1cwyZ2KB040=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId AppX90nv6nhay5n6a98fnetv7tpk64pp35es
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash kQz/gLoO7oo=
		break
	    }
	    # Internet Explorer
	    # https://www.microsoft.com/pt-br/download/internet-explorer.aspx
	    'ie|internet|explorer' {
		Write-Output "`nChanging to Explorer as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId IE.HTTP
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash 98qL1nQ8CNQ=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId IE.HTTPS
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash m1UWOHOva/s=
		break
	    }
	    # Mozilla Firefox
	    # https://www.mozilla.org/
	    'ff|firefox' {
		Write-Output "`nChanging to Firefox as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId FirefoxURL-308046B0AF4A39CB
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash yWnRoYQTfbs=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId FirefoxURL-308046B0AF4A39CB
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash IhKJ36zo2D8=
		break
	    }
	    # Opera Browser
	    # https://www.opera.com/
	    'ob|opera' {
		Write-Output "`nChanging to Opera as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId OperaStable
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash EBgmhN4KR60=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId OperaStable
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash 84VcShSmrms=
		break
	    }
	    # The Waterfox Project
	    # https://www.waterfoxproject.org/
	    'wf|waterfox' {
		Write-Output "`nChanging to Waterfox as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId WaterfoxURL-6F940AC27A98DD61
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash e3oYc6aZ6UA=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId WaterfoxURL-6F940AC27A98DD61
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash j9aaZZ30p3Y=
		break
	    }
	    # Vivaldi
	    # https://vivaldi.com
	    'vi|vivaldi' {
		Write-Output "`nChanging to Vivaldi as the default browser..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId VivaldiHTM.AQHSUMD27WSPRY7GH5RXFKR6WM
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash Pr6mP1NhKy0=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId VivaldiHTM.AQHSUMD27WSPRY7GH5RXFKR6WM
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash wxeuCoUyJR0=
		break
	    }
	}
}



Function RestoreTheDefaultBrowser {
	# Call this function in the following way:
	#ChangeTheDefaultBrowser bb
	#ChangeTheDefaultBrowser gc
	#ChangeTheDefaultBrowser cb
	#ChangeTheDefaultBrowser me
	#ChangeTheDefaultBrowser ie
	#ChangeTheDefaultBrowser ff
	#ChangeTheDefaultBrowser ob
	#ChangeTheDefaultBrowser wf
	param($defaultBrowser)

	$regKey = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
	$regKeyHttp = $regKey -f 'http'
	$regKeyHttps = $regKey -f 'https'

	switch -Regex ($defaultBrowser.ToLower()) {
		# Microsoft Edge
		# https://www.microsoft.com/pt-br/windows/microsoft-edge
	    'me|edge' {
		Write-Output "`nChanging back to Edge..."
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name ProgId AppX90nv6nhay5n6a98fnetv7tpk64pp35es
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttp  -name Hash 1cwyZ2KB040=
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name ProgId AppX90nv6nhay5n6a98fnetv7tpk64pp35es
		Set-ItemProperty -Force -PassThru -Verbose $regKeyHttps -name Hash kQz/gLoO7oo=
		break
	    }
	}
    }





function Set-DefaultBrowserFirefoxViaKeyPress {
	Add-Type -AssemblyName 'System.Windows.Forms'
	Start-Process $env:windir\system32\control.exe -LoadUserProfile -Wait -ArgumentList '/name Microsoft.DefaultPrograms /page pageDefaultProgram\pageAdvancedSettings?pszAppName=Firefox-308046B0AF4A39CB'
	Sleep 10
	[System.Windows.Forms.SendKeys]::SendWait("{TAB}{TAB}{TAB}{TAB}{TAB} {ENTER}{ENTER} ")
}
