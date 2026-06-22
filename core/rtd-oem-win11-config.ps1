# :: --    --
# :: 					Windows PowerShell Script
# ::
# ::             			A D M I N   S C R I P T
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::// OEM Windows 11 Configuration Script //:::::::::::::::::::::::::// Windows //::::::
# ::
# :: Author:			RTD Team
# :: Version: 			1.0
# ::
# :: 	This Script Source:	https://github.com/vonschutter/RTD-Setup
# ::
# :: Purpose: 	The purpose of the script is to:
# ::		- Configure a fresh Windows 11 VM, VDI, or workstation for RTD use.
# ::		- Remove Windows consumer bloat and sponsored content when using the Aggressive preset.
# ::		- Reduce background activity, telemetry, advertising surfaces, and suggestions.
# ::		- Apply conservative performance-focused service defaults suitable for VM and VDI use.
# ::		- Install the standard RTD application set and virtualization guest tools.
# ::
# ::		NOTE: This script intentionally keeps Windows Defender, Windows Update, Store dependencies,
# ::		      WebView2, networking, event logging, and core management services.
# ::
# :: Usage: 	Run from an elevated PowerShell session, or allow the script to relaunch itself elevated:
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-win11-config.ps1
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-win11-config.ps1 -Preset Minimal
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-win11-config.ps1 -SkipSoftware
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-win11-config.ps1 -Restart
# ::
# :: Presets:	Aggressive  Default. Removes consumer apps and disables non-essential noise.
# ::		Minimal     Keeps bundled apps but disables telemetry, ads, and suggestions.
# ::
# :: Background: This script is shared in the hopes that someone will find it useful. To encourage sharing changes
# :: 		 back to the source this script is released under the GPL v3. (see source location for details)
# ::		 https://github.com/vonschutter/RTD-Setup/raw/master/LICENSE.md
# ::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	NOTE:	These terminal program(s) are written and documented to a very high degree. The reason for doing this is that
#		these apps are seldom changed and when they are, it is useful to be able to understand why and how
#		things were built. Obviously, this becomes a useful learning tool as well; for all people that want to
#		learn how to write admin scripts. It is a good and necessary practice to document extensively and follow
#		patterns when building your own apps and config scripts. Failing to do so will result in a costly mess
#		for any organization after some years and people turnover.
#
#		As a general rule, we prefer using functions extensively because this makes it easier to manage the script
#		and facilitates several users working on the same scripts over time.
#
#		Taxonomy of this script: we prioritize the use of functions over monolithic script writing, and proper indentation
#		to make the script more readable. Each function shall also be documented to the point of the obvious.
#		Suggested function structure per google guidelines and as per the suggestions of
#		John Savill "PowerShell Master Class series":
#
#		function function_name {
#			# Documentation and comments...
#			...code...
#		}

[CmdletBinding()]
param(
    [ValidateSet("Aggressive", "Minimal")]
    [string]$Preset = "Aggressive",

    [switch]$Restart,

    [switch]$SkipSoftware
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$Script:RestartRequired = $false
$Script:RtdRoot = "C:\RTD"
$Script:LogDir = Join-Path $Script:RtdRoot "log"
$Script:SetupLog = "C:\setup.log"
$Script:ChocoExe = $null
$Script:SoftwareFailures = New-Object System.Collections.Generic.List[string]
$Script:WarningCount = 0
$Script:VirtualizationPlatform = $null

# Centralized logging keeps the console, setup log, and RTD log aligned. Most
# actions are best-effort on Windows images because exact components vary by
# edition, build, OEM media, and whether the script runs before or after OOBE.
function Write-RtdLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "OK")]
        [string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    if ($Level -in @("WARN", "ERROR")) {
        $Script:WarningCount++
    }
    try {
        Add-Content -Path $Script:SetupLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
        Add-Content -Path (Join-Path $Script:LogDir "rtd-oem-win11-config.log") -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[WARN] Unable to write to log file: $($_.Exception.Message)"
    }
}

# Machine-readable progress events allow a graphical frontend to track major
# phases without parsing localized or descriptive log text. Console users see
# the markers as harmless status lines.
function Write-RtdStep {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("initialize", "tuning", "software", "complete")]
        [string]$Step,

        [Parameter(Mandatory = $true)]
        [ValidateSet("start", "done", "warning", "skipped", "restart", "restart-required")]
        [string]$State
    )

    Write-Output "RTD_STEP:${Step}:${State}"
}

# Windows hardening and AppX removal require elevation. This helper keeps the
# permission check in one place so the script can relaunch itself cleanly.
function Test-RtdAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunch the current script through UAC when it is started from a non-admin
# shell. The selected preset and restart choice are preserved for the elevated run.
function Start-RtdElevated {
    if (Test-RtdAdmin) {
        return
    }

    Write-Host "RTD Windows 11 configuration requires administrative privileges. Relaunching elevated..."
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $PSCommandPath),
        "-Preset", $Preset
    )
    if ($Restart) {
        $arguments += "-Restart"
    }
    if ($SkipSoftware) {
        $arguments += "-SkipSoftware"
    }

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Prepare the RTD working folders and transcript before changing system state.
# The Windows build warning catches accidental use on Windows 10 without blocking
# an administrator who deliberately runs the script.
function Initialize-RtdWin11Config {
    Start-RtdElevated

    New-Item -Path $Script:RtdRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $Script:LogDir -ItemType Directory -Force | Out-Null
    New-Item -Path $Script:SetupLog -ItemType File -Force | Out-Null

    try {
        Start-Transcript -Path (Join-Path $Script:LogDir "rtd-oem-win11-config-transcript.log") -Append -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-RtdLog "Transcript logging could not be started: $($_.Exception.Message)" "WARN"
    }

    $build = [Environment]::OSVersion.Version.Build
    Write-RtdLog "Detected Windows build $build."
    if ($build -lt 22000) {
        Write-RtdLog "This script is intended for Windows 11 build 22000 or newer. Continuing because PowerShell execution was requested explicitly." "WARN"
    }
}

# Registry writes are wrapped so policy edits are idempotent and missing keys are
# created automatically. Failures are logged as warnings to avoid stopping a long
# image-preparation run over one unavailable policy path.
function Set-RtdRegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Value,

        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$Type = "DWord"
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    } catch {
        Write-RtdLog "Registry write failed: $Path\$Name -> $Value ($($_.Exception.Message))" "WARN"
    }
}

# Some cleanup tasks need to remove existing per-user startup entries. Missing
# values are expected on clean installs, so absence is treated as success.
function Remove-RtdRegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-RtdLog "Registry value removal failed: $Path\$Name ($($_.Exception.Message))" "WARN"
    }
}

# Service names can be exact names or wildcard patterns for per-user services
# such as CDPUserSvc_*. Each matching service is updated independently.
function Set-RtdServiceStartup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateSet("Automatic", "Manual", "Disabled")]
        [string]$StartupType = "Manual",

        [switch]$Stop
    )

    $services = Get-Service -Name $Name -ErrorAction SilentlyContinue
    foreach ($service in $services) {
        try {
            if ($Stop -and $service.Status -eq "Running") {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $service.Name -StartupType $StartupType -ErrorAction Stop
            Write-RtdLog "Service $($service.Name) set to $StartupType."
        } catch {
            Write-RtdLog "Service update failed for $($service.Name): $($_.Exception.Message)" "WARN"
        }
    }
}

# Scheduled tasks are disabled by exact task path/name. Windows build differences
# are tolerated because several telemetry tasks are absent on some editions.
function Disable-RtdScheduledTask {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null
            Write-RtdLog "Scheduled task disabled: $TaskPath$TaskName."
        }
    } catch {
        Write-RtdLog "Could not disable scheduled task $($TaskPath)$($TaskName): $($_.Exception.Message)" "WARN"
    }
}

# Reduce diagnostic collection and feedback prompts. This combines policy keys,
# current-user privacy settings, telemetry services, and known scheduled tasks
# that periodically collect compatibility or customer-experience data.
function Disable-RtdWindows11Telemetry {
    Write-RtdLog "Disabling Windows 11 telemetry and feedback collection."

    # Machine policy keys apply broadly and survive new user creation.
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DisableOneSettingsDownloads" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
    # Current-user values suppress tailored experiences and feedback cadence.
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0 "QWord"

    # Disable telemetry-specific services, but leave core diagnostics available
    # manually so support troubleshooting still works when needed.
    Set-RtdServiceStartup "DiagTrack" "Disabled" -Stop
    Set-RtdServiceStartup "dmwappushservice" "Disabled" -Stop
    Set-RtdServiceStartup "diagnosticshub.standardcollector.service" "Disabled" -Stop
    Set-RtdServiceStartup "DPS" "Manual"
    Set-RtdServiceStartup "WdiServiceHost" "Manual"
    Set-RtdServiceStartup "WdiSystemHost" "Manual"
    Set-RtdServiceStartup "WerSvc" "Manual"

    # These tasks are responsible for compatibility inventory, CEIP collection,
    # feedback prompts, and queued error reporting.
    Disable-RtdScheduledTask "\Microsoft\Windows\Application Experience\" "Microsoft Compatibility Appraiser"
    Disable-RtdScheduledTask "\Microsoft\Windows\Application Experience\" "ProgramDataUpdater"
    Disable-RtdScheduledTask "\Microsoft\Windows\Application Experience\" "StartupAppTask"
    Disable-RtdScheduledTask "\Microsoft\Windows\Autochk\" "Proxy"
    Disable-RtdScheduledTask "\Microsoft\Windows\Customer Experience Improvement Program\" "Consolidator"
    Disable-RtdScheduledTask "\Microsoft\Windows\Customer Experience Improvement Program\" "UsbCeip"
    Disable-RtdScheduledTask "\Microsoft\Windows\DiskDiagnostic\" "Microsoft-Windows-DiskDiagnosticDataCollector"
    Disable-RtdScheduledTask "\Microsoft\Windows\Feedback\Siuf\" "DmClient"
    Disable-RtdScheduledTask "\Microsoft\Windows\Feedback\Siuf\" "DmClientOnScenarioDownload"
    Disable-RtdScheduledTask "\Microsoft\Windows\Windows Error Reporting\" "QueueReporting"
}

# Disable Windows consumer-content pipelines. These settings reduce start-menu
# suggestions, lock-screen promotions, File Explorer sync-provider prompts, and
# web-backed search results that create noise in a managed VM/VDI image.
function Disable-RtdWindows11SuggestionsAndAds {
    Write-RtdLog "Disabling Windows 11 suggestions, ads, consumer content, and web search noise."

    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableConsumerAccountStateContent" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" 1

    # ContentDeliveryManager owns most of the consumer suggestions, silent app
    # installs, rotating lock screen content, and subscribed-content toggles.
    $contentDeliveryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $contentDeliveryValues = @(
        "ContentDeliveryAllowed",
        "FeatureManagementEnabled",
        "OemPreInstalledAppsEnabled",
        "PreInstalledAppsEnabled",
        "PreInstalledAppsEverEnabled",
        "SilentInstalledAppsEnabled",
        "SoftLandingEnabled",
        "SystemPaneSuggestionsEnabled",
        "RotatingLockScreenEnabled",
        "RotatingLockScreenOverlayEnabled",
        "SubscribedContent-310093Enabled",
        "SubscribedContent-314563Enabled",
        "SubscribedContent-338387Enabled",
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-338393Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled",
        "SubscribedContent-353698Enabled",
        "SubscribedContent-88000326Enabled"
    )

    foreach ($valueName in $contentDeliveryValues) {
        Set-RtdRegistryValue $contentDeliveryPath $valueName 0
    }

    # Explorer and Search values keep local navigation predictable and prevent
    # search from mixing local app/file results with Bing-backed suggestions.
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
}

# Remove taskbar and shell entry points for cloud/news/chat features that are
# not useful in most RTD workstation images and often start background processes.
function Disable-RtdWindows11CopilotWidgetsChat {
    Write-RtdLog "Disabling Copilot, Widgets, Chat, and related taskbar entry points."

    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0
}

# Restrict Store/UWP apps from running in the background and accessing common
# sensor-style capabilities. The AppPrivacy value 2 means "force deny" by policy.
function Disable-RtdWindows11BackgroundApps {
    Write-RtdLog "Disabling background app execution where policy allows it."

    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsActivateWithVoice" 2
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessLocation" 2
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessMotion" 2
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessNotifications" 2
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsSyncWithDevices" 2
}

# Turn off game capture and Xbox services. These features are useful on gaming
# workstations but add background services and overlays to standard VM/VDI images.
function Disable-RtdWindows11Gaming {
    Write-RtdLog "Disabling Game DVR, Game Bar, and Xbox background services."

    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Set-RtdRegistryValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0

    Set-RtdServiceStartup "BcastDVRUserService*" "Disabled" -Stop
    Set-RtdServiceStartup "XblAuthManager" "Disabled" -Stop
    Set-RtdServiceStartup "XblGameSave" "Disabled" -Stop
    Set-RtdServiceStartup "XboxGipSvc" "Disabled" -Stop
    Set-RtdServiceStartup "XboxNetApiSvc" "Disabled" -Stop
}

# OneDrive is removed only in the Aggressive preset. The policy blocks sync for
# future users, startup entries prevent relaunch, and setup /uninstall removes
# the installed client when present.
function Disable-RtdWindows11OneDrive {
    Write-RtdLog "Disabling and uninstalling OneDrive."

    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSync" 1
    Remove-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive"
    Remove-RtdRegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive"

    $oneDriveSetup = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($oneDriveSetup) {
        try {
            Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -WindowStyle Hidden
            Write-RtdLog "OneDrive uninstall command completed."
            $Script:RestartRequired = $true
        } catch {
            Write-RtdLog "OneDrive uninstall failed: $($_.Exception.Message)" "WARN"
        }
    }
}

# Apply user-facing defaults that make an image easier to support: less visual
# overhead, file extensions visible, hidden files visible, left-aligned taskbar,
# and no Explorer startup delay.
function Set-RtdWindows11PerformanceUi {
    Write-RtdLog "Applying performance-focused Explorer, UI, and privacy defaults."

    Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
    Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "100" "String"
    Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
}

# Edge is left installed because Windows components depend on it, but first-run,
# sidebar, shopping, suggestions, feedback, and diagnostic reporting are reduced.
function Set-RtdWindows11EdgePolicy {
    Write-RtdLog "Reducing Microsoft Edge first-run, sidebar, shopping, and feedback noise."

    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    Set-RtdRegistryValue $edgePolicyPath "HideFirstRunExperience" 1
    Set-RtdRegistryValue $edgePolicyPath "UserFeedbackAllowed" 0
    Set-RtdRegistryValue $edgePolicyPath "PersonalizationReportingEnabled" 0
    Set-RtdRegistryValue $edgePolicyPath "ShowRecommendationsEnabled" 0
    Set-RtdRegistryValue $edgePolicyPath "EdgeShoppingAssistantEnabled" 0
    Set-RtdRegistryValue $edgePolicyPath "HubsSidebarEnabled" 0
    Set-RtdRegistryValue $edgePolicyPath "SearchSuggestEnabled" 0
    Set-RtdRegistryValue $edgePolicyPath "DiagnosticData" 0
}

# Tune non-essential services for VM/VDI use. Services that are rarely useful in
# a managed image are disabled; support-adjacent services are left manual so an
# administrator can still start them when needed.
function Optimize-RtdWindows11Services {
    Write-RtdLog "Optimizing non-essential Windows 11 services."

    $disableServices = @(
        "MapsBroker",
        "RetailDemo",
        "RemoteRegistry",
        "WMPNetworkSvc",
        "PhoneSvc",
        "SharedAccess",
        "lfsvc",
        "WalletService",
        "MessagingService*",
        "PimIndexMaintenanceSvc*",
        "UnistoreSvc*",
        "UserDataSvc*",
        "CDPUserSvc*",
        "SysMain",
        "WSearch"
    )

    foreach ($serviceName in $disableServices) {
        Set-RtdServiceStartup $serviceName "Disabled" -Stop
    }

    # Manual services stay available without automatically consuming resources
    # during normal boot and user sign-in.
    $manualServices = @(
        "Fax",
        "Spooler",
        "TabletInputService",
        "WbioSrvc",
        "SEMgrSvc",
        "PcaSvc",
        "TrkWks",
        "WerSvc",
        "wisvc",
        "WpnService",
        "CDPSvc"
    )

    foreach ($serviceName in $manualServices) {
        Set-RtdServiceStartup $serviceName "Manual"
    }
}

# Remove both currently installed AppX packages and provisioned packages. The
# provisioned package removal is what prevents removed apps from coming back for
# new users created after the image is finalized.
function Remove-RtdAppxPackagePattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    Write-RtdLog "Removing AppX package pattern: $Pattern"

    # Installed packages affect existing user profiles.
    try {
        Get-AppxPackage -AllUsers -Name $Pattern -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
                Write-RtdLog "Removed installed package $($_.Name)." "OK"
            } catch {
                try {
                    Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop
                    Write-RtdLog "Removed current-user package $($_.Name)." "OK"
                } catch {
                    Write-RtdLog "Could not remove installed package $($_.Name): $($_.Exception.Message)" "WARN"
                }
            }
        }
    } catch {
        Write-RtdLog "Installed AppX query failed for ${Pattern}: $($_.Exception.Message)" "WARN"
    }

    # Provisioned packages affect future user profiles created from this image.
    try {
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $Pattern } |
            ForEach-Object {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null
                    Write-RtdLog "Removed provisioned package $($_.DisplayName)." "OK"
                } catch {
                    Write-RtdLog "Could not remove provisioned package $($_.DisplayName): $($_.Exception.Message)" "WARN"
                }
            }
    } catch {
        Write-RtdLog "Provisioned AppX query failed for ${Pattern}: $($_.Exception.Message)" "WARN"
    }
}

# Curated consumer AppX package list for Windows 11. The list avoids core
# platform components such as Store dependencies, WebView2, Defender, Update,
# networking, and management tooling.
function Remove-RtdWindows11BloatApps {
    Write-RtdLog "Removing Windows 11 consumer AppX packages."

    $bloatPackages = @(
        "Clipchamp.Clipchamp",
        "Microsoft.BingNews",
        "Microsoft.BingSearch",
        "Microsoft.BingWeather",
        "Microsoft.GamingApp",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.OutlookForWindows",
        "Microsoft.People",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.SkypeApp",
        "Microsoft.Todos",
        "Microsoft.Wallet",
        "Microsoft.Whiteboard",
        "Microsoft.Windows.DevHome",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "MicrosoftCorporationII.QuickAssist",
        "MicrosoftTeams",
        "MSTeams"
    )

    # WebExperience hosts Widgets/news surfaces. It is removed only in Aggressive
    # mode because some users may prefer to keep that shell component available.
    if ($Preset -eq "Aggressive") {
        $bloatPackages += @(
            "MicrosoftWindows.Client.WebExperience"
        )
    }

    foreach ($package in $bloatPackages | Sort-Object -Unique) {
        Remove-RtdAppxPackagePattern $package
    }

    $Script:RestartRequired = $true
}

# Install Chocolatey only when it is not already available. The bootstrap command
# follows Chocolatey's documented administrative PowerShell installation method.
function Initialize-RtdChocolatey {
    $existing = Get-Command "choco.exe" -ErrorAction SilentlyContinue
    if ($existing) {
        $Script:ChocoExe = $existing.Source
        Write-RtdLog "Chocolatey is already available at $($Script:ChocoExe)." "OK"
        return $true
    }

    Write-RtdLog "Chocolatey is not installed; bootstrapping the package manager."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $installer = (New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1")
        Invoke-Expression $installer | Out-Host

        $machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
        $env:Path = "$machinePath;$userPath"

        $installed = Get-Command "choco.exe" -ErrorAction SilentlyContinue
        if (-not $installed) {
            $defaultChoco = Join-Path $env:ProgramData "chocolatey\bin\choco.exe"
            if (Test-Path $defaultChoco) {
                $Script:ChocoExe = $defaultChoco
            } else {
                throw "Chocolatey bootstrap completed but choco.exe could not be located."
            }
        } else {
            $Script:ChocoExe = $installed.Source
        }

        Write-RtdLog "Chocolatey installation completed: $($Script:ChocoExe)." "OK"
        return $true
    } catch {
        $message = "Chocolatey installation failed: $($_.Exception.Message)"
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }
}

# Chocolatey installation is idempotent, so this helper can safely request the
# desired package on both clean images and previously configured workstations.
function Install-RtdChocolateyPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Package,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [string[]]$PackageParameters = @()
    )

    if (-not $Script:ChocoExe -or -not (Test-Path $Script:ChocoExe)) {
        $message = "Cannot install $DisplayName because Chocolatey is unavailable."
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }

    Write-RtdLog "Ensuring software is installed: $DisplayName ($Package)."
    $chocoArguments = @("install", $Package, "-y", "--no-progress", "--no-desktopshortcuts")
    if ($PackageParameters -and $PackageParameters.Count -gt 0) {
        $chocoArguments += @("--params", ($PackageParameters -join " "))
    }

    try {
        & $Script:ChocoExe @chocoArguments | Out-Host
        $exitCode = $LASTEXITCODE
        if ($exitCode -in @(0, 1641, 3010)) {
            Write-RtdLog "$DisplayName is installed (Chocolatey exit code $exitCode)." "OK"
            if ($exitCode -in @(1641, 3010)) {
                $Script:RestartRequired = $true
            }
            return $true
        }

        throw "Chocolatey returned exit code $exitCode."
    } catch {
        $message = "Installation failed for ${DisplayName}: $($_.Exception.Message)"
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }
}

# Detect the active virtualization platform from a few stable hardware identity
# sources. Manufacturer/model is usually enough, while BIOS and baseboard text
# help when vendors expose generic values through Win32_ComputerSystem.
function Get-RtdVirtualizationPlatform {
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
        $baseBoard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue

        $fingerprintParts = @(
            $computerSystem.Manufacturer,
            $computerSystem.Model,
            $bios.Manufacturer,
            ($bios.SMBIOSBIOSVersion -join " "),
            $bios.Version,
            $baseBoard.Manufacturer,
            $baseBoard.Product
        ) | Where-Object { $_ -and $_.ToString().Trim() }

        $virtualizationIdentity = ($fingerprintParts -join " ").Trim()
        Write-RtdLog "Virtualization detection fingerprint: $virtualizationIdentity."

        switch -Regex ($virtualizationIdentity) {
            "Microsoft Corporation.*Virtual|Hyper-V" { return "hyperv" }
            "VMware" { return "vmware" }
            "VirtualBox|Oracle" { return "virtualbox" }
            "QEMU|KVM|Red Hat|RHV|oVirt|Bochs|Proxmox" { return "kvm" }
            "Xen" { return "xen" }
            default { return "physical" }
        }
    } catch {
        Write-RtdLog "Virtualization guest-tool detection failed: $($_.Exception.Message)" "WARN"
        return "unknown"
    }
}

# Query the virtio-win archive index, select the numerically highest release,
# and build the download URL for the guest-tools bundle. Fallback entries are
# kept because the upstream listing service is occasionally filtered or mirrored.
function Get-RtdLatestVirtioGuestTools {
    $indexCandidates = @(
        "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D",
        "https://fedora-virt.repo.nfrance.com/virtio-win/direct-downloads/archive-virtio/"
    )

    $artifactTemplates = @(
        "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/{0}/virtio-win-guest-tools.exe",
        "https://fedora-virt.repo.nfrance.com/virtio-win/direct-downloads/archive-virtio/{0}/virtio-win-guest-tools.exe",
        "https://fedora-virt.repo.nfrance.com/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
    )

    $releasePattern = 'virtio-win-(\d+)\.(\d+)\.(\d+)(?:-(\d+))?/'
    $releases = New-Object System.Collections.Generic.List[object]

    foreach ($indexUrl in $indexCandidates) {
        try {
            Write-RtdLog "Inspecting virtio-win archive index: $indexUrl"
            $response = Invoke-WebRequest -Uri $indexUrl -UseBasicParsing -ErrorAction Stop
            foreach ($match in [regex]::Matches($response.Content, $releasePattern)) {
                $revision = if ($match.Groups[4].Success) { [int]$match.Groups[4].Value } else { 0 }
                $releases.Add([pscustomobject]@{
                    Version = $match.Value.TrimEnd("/")
                    Major = [int]$match.Groups[1].Value
                    Minor = [int]$match.Groups[2].Value
                    Patch = [int]$match.Groups[3].Value
                    Revision = $revision
                })
            }
        } catch {
            Write-RtdLog "Could not inspect virtio-win archive index $indexUrl: $($_.Exception.Message)" "WARN"
        }
    }

    $latestRelease = $releases |
        Sort-Object Major, Minor, Patch, Revision -Descending |
        Select-Object -First 1

    if ($latestRelease) {
        foreach ($template in $artifactTemplates[0..1]) {
            $url = $template -f $latestRelease.Version
            try {
                Write-RtdLog "Validating virtio guest-tools download URL: $url"
                $head = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
                if ($head.StatusCode -ge 200 -and $head.StatusCode -lt 400) {
                    return [pscustomobject]@{
                        Version = $latestRelease.Version
                        Url = $url
                    }
                }
            } catch {
                Write-RtdLog "virtio guest-tools URL check failed for $url: $($_.Exception.Message)" "WARN"
            }
        }
    }

    $fallbackVersion = if ($latestRelease) { $latestRelease.Version } else { "latest-virtio" }
    return [pscustomobject]@{
        Version = $fallbackVersion
        Url = $artifactTemplates[2]
    }
}

# Use the upstream guest-tools bundle for KVM/QEMU guests instead of depending
# on Chocolatey packages that may lag behind the virtio driver release cadence.
function Install-RtdVirtioGuestTools {
    $download = Get-RtdLatestVirtioGuestTools
    $installerPath = Join-Path (Join-Path $Script:RtdRoot "cache") "virtio-win-guest-tools.exe"

    try {
        New-Item -Path (Split-Path $installerPath -Parent) -ItemType Directory -Force | Out-Null
        Write-RtdLog "Downloading virtio guest tools release $($download.Version) from $($download.Url)."
        Invoke-WebRequest -Uri $download.Url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop

        $process = Start-Process -FilePath $installerPath -ArgumentList @("/passive", "/norestart", "/log", (Join-Path $Script:LogDir "virtio_log.txt")) -Wait -PassThru
        if ($process.ExitCode -in @(0, 1641, 3010)) {
            Write-RtdLog "virtio guest tools installed successfully from release $($download.Version) (exit code $($process.ExitCode))." "OK"
            if ($process.ExitCode -in @(1641, 3010)) {
                $Script:RestartRequired = $true
            }
            return $true
        }

        throw "virtio guest tools installer returned exit code $($process.ExitCode)."
    } catch {
        $message = "virtio guest tools installation failed: $($_.Exception.Message)"
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }
}

# Windows includes Hyper-V integration components. Other detected hypervisors
# receive the same guest utilities requested by the Windows 10 configuration.
function Install-RtdVirtualizationGuestTools {
    $platform = Get-RtdVirtualizationPlatform
    $Script:VirtualizationPlatform = $platform

    switch ($platform) {
        "vmware" {
            Install-RtdChocolateyPackage "vmware-tools" "VMware Tools" | Out-Null
        }
        "virtualbox" {
            Install-RtdChocolateyPackage "virtualbox-guest-additions-guest.install" "VirtualBox Guest Additions" | Out-Null
        }
        "kvm" {
            Set-RtdRegistryValue "HKLM:\Software\Policies\Microsoft\Windows NT\Driver Signing" "BehaviorOnFailedVerify" 1
            Install-RtdVirtioGuestTools | Out-Null
        }
        "hyperv" {
            Write-RtdLog "Hyper-V guest detected; integration services are built into Windows 11." "OK"
        }
        "xen" {
            Write-RtdLog "Xen guest detected, but no RTD-managed guest-tools package is currently defined. Install the vendor tools manually if this image requires them." "WARN"
        }
        "unknown" {
            Write-RtdLog "Virtualization detection did not complete cleanly. Guest-tool installation was skipped." "WARN"
        }
        default {
            Write-RtdLog "No supported virtual-machine platform was detected; guest-tool installation is not required."
        }
    }
}

# Preserve the Windows 10 workflow's O&O ShutUp10++ deployment while using the
# current Windows 11-oriented recommended profile. Verify the signed executable
# before applying the downloaded configuration silently.
function Install-RtdShutUp10 {
    $toolDirectory = Join-Path $Script:RtdRoot "tools\OOSU10"
    $executable = Join-Path $toolDirectory "OOSU10.exe"
    $configuration = Join-Path $toolDirectory "ooshutup10-recommended.cfg"

    try {
        New-Item -Path $toolDirectory -ItemType Directory -Force | Out-Null
        Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $executable -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/ooshutup10_recommended.cfg" -OutFile $configuration -UseBasicParsing -ErrorAction Stop

        $signature = Get-AuthenticodeSignature -FilePath $executable
        if ($signature.Status -ne "Valid") {
            throw "Authenticode validation returned $($signature.Status)."
        }

        $process = Start-Process -FilePath $executable -ArgumentList @($configuration, "/quiet") -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "O&O ShutUp10++ returned exit code $($process.ExitCode)."
        }

        Write-RtdLog "O&O ShutUp10++ recommended settings were applied." "OK"
        return $true
    } catch {
        $message = "O&O ShutUp10++ deployment failed: $($_.Exception.Message)"
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }
}

# The Windows 10 workflow enabled the legacy Windows Media Player optional
# feature. Retain that behavior when the feature exists on the Windows 11 image.
function Enable-RtdWindowsMediaPlayer {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -ErrorAction Stop
        if ($feature.State -eq "Enabled") {
            Write-RtdLog "Windows Media Player optional feature is already enabled." "OK"
            return
        }

        Enable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart -All -ErrorAction Stop | Out-Null
        $Script:RestartRequired = $true
        Write-RtdLog "Windows Media Player optional feature was enabled." "OK"
    } catch {
        Write-RtdLog "Windows Media Player optional feature is unavailable or could not be enabled: $($_.Exception.Message)" "WARN"
    }
}

# Install the software selected by default in rtd-oem-win10-config.ps1. Optional
# commented bundles (games, graphics, PDF tools, and LibreOffice) remain excluded.
function Install-RtdWindows11Software {
    Write-RtdLog "Starting standard RTD software deployment."

    if (Initialize-RtdChocolatey) {
        $software = @(
            @{ Package = "chocolatey-core.extension"; Name = "Chocolatey Core Extension"; Parameters = @() },
            @{ Package = "chocolateygui"; Name = "Chocolatey GUI"; Parameters = @() },
            @{ Package = "7zip"; Name = "7-Zip"; Parameters = @() },
            @{ Package = "vscode"; Name = "Visual Studio Code"; Parameters = @() },
            @{ Package = "filezilla"; Name = "FileZilla"; Parameters = @() },
            @{ Package = "putty"; Name = "PuTTY"; Parameters = @() },
            @{ Package = "notepadplusplus"; Name = "Notepad++"; Parameters = @() },
            @{ Package = "vlc"; Name = "VLC media player"; Parameters = @() },
            @{ Package = "brave"; Name = "Brave Browser"; Parameters = @() },
            @{ Package = "firefox"; Name = "Mozilla Firefox"; Parameters = @("/NoDesktopShortcut") },
            @{ Package = "microsoft-office-deployment"; Name = "Microsoft Office Deployment Tool"; Parameters = @() }
        )

        foreach ($item in $software) {
            Install-RtdChocolateyPackage -Package $item.Package -DisplayName $item.Name -PackageParameters $item.Parameters | Out-Null
        }
    } else {
        Write-RtdLog "Chocolatey-dependent application installs were skipped after bootstrap failure." "ERROR"
    }

    Install-RtdVirtualizationGuestTools
    Install-RtdShutUp10 | Out-Null
    Enable-RtdWindowsMediaPlayer

    if ($Script:SoftwareFailures.Count -gt 0) {
        Write-RtdLog "Software deployment completed with $($Script:SoftwareFailures.Count) failure(s)." "WARN"
        foreach ($failure in $Script:SoftwareFailures) {
            Write-RtdLog "Software deployment issue: $failure" "WARN"
        }
    } else {
        Write-RtdLog "Standard RTD software deployment completed successfully." "OK"
    }
}

# Minimal keeps Windows app payloads intact while reducing telemetry, ads,
# background app behavior, gaming overlays, and noisy shell/Edge defaults.
function Run-RtdWindows11Minimal {
    Disable-RtdWindows11Telemetry
    Disable-RtdWindows11SuggestionsAndAds
    Disable-RtdWindows11CopilotWidgetsChat
    Disable-RtdWindows11BackgroundApps
    Disable-RtdWindows11Gaming
    Set-RtdWindows11PerformanceUi
    Set-RtdWindows11EdgePolicy
}

# Aggressive starts with Minimal, then removes OneDrive, tunes services, and
# removes consumer AppX payloads for a cleaner VM/VDI template.
function Run-RtdWindows11Aggressive {
    Run-RtdWindows11Minimal
    Disable-RtdWindows11OneDrive
    Optimize-RtdWindows11Services
    Remove-RtdWindows11BloatApps
}

# Stop transcript logging and optionally restart. AppX removal and service
# changes often need a reboot before the final user experience is accurate.
function Complete-RtdWindows11Config {
    Write-RtdStep "complete" "start"
    $hadOperationalWarnings = $Script:WarningCount -gt 0

    try {
        Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    } catch {
        # Ignore transcript shutdown errors.
    }

    if ($Restart) {
        Write-RtdLog "Restart requested. Restarting Windows now."
        Write-RtdStep "complete" "restart"
        Start-Sleep -Seconds 1
        Restart-Computer -Force
        return
    }

    if ($Script:SoftwareFailures.Count -gt 0 -or $hadOperationalWarnings) {
        Write-RtdLog "Configuration complete with one or more unresolved warnings. Review the detailed log before finalizing the image." "WARN"
        Write-RtdStep "complete" "warning"
    } elseif ($Script:RestartRequired) {
        Write-RtdLog "Configuration complete. A restart is recommended before testing performance or finalizing the image." "WARN"
        Write-RtdStep "complete" "restart-required"
    } else {
        Write-RtdLog "Configuration complete." "OK"
        Write-RtdStep "complete" "done"
    }
}

Write-RtdStep "initialize" "start"
Initialize-RtdWin11Config
Write-RtdStep "initialize" "done"

# Dispatch the selected preset after initialization so logging, elevation, and
# build checks are complete before any system changes are attempted.
Write-RtdStep "tuning" "start"
switch ($Preset) {
    "Minimal" {
        Write-RtdLog "Running Windows 11 Minimal preset."
        Run-RtdWindows11Minimal
    }
    default {
        Write-RtdLog "Running Windows 11 Aggressive preset."
        Run-RtdWindows11Aggressive
    }
}
Write-RtdStep "tuning" "done"

if ($SkipSoftware) {
    Write-RtdLog "Software deployment was skipped because -SkipSoftware was specified."
    Write-RtdStep "software" "skipped"
} else {
    Write-RtdStep "software" "start"
    Install-RtdWindows11Software
    if ($Script:SoftwareFailures.Count -gt 0) {
        Write-RtdStep "software" "warning"
    } else {
        Write-RtdStep "software" "done"
    }
}

Complete-RtdWindows11Config
