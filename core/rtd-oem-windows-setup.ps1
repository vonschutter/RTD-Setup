# :: --    --
# :: 					Windows PowerShell Script
# ::
# ::             			A D M I N   S C R I P T
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::// OEM Windows Configuration Script //:::::::::::::::::::::::::// Windows //::::::
# ::
# :: Author:			RTD Team
# :: Version: 			1.0
# ::
# :: 	This Script Source:	https://github.com/vonschutter/RTD-Setup
# ::
# :: Purpose: 	The purpose of the script is to:
# ::		- Configure a fresh Windows VM, VDI, or workstation for RTD use.
# ::		- Remove Windows consumer bloat and sponsored content when using the Aggressive preset.
# ::		- Reduce background activity, telemetry, advertising surfaces, and suggestions.
# ::		- Apply conservative performance-focused service defaults suitable for VM and VDI use.
# ::		- Install the standard RTD application set and virtualization guest tools.
# ::
# ::		NOTE: This script intentionally keeps Windows Defender, Windows Update, Store dependencies,
# ::		      WebView2, networking, event logging, and core management services.
# ::
# :: Usage: 	Run from an elevated PowerShell session, or allow the script to relaunch itself elevated:
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-windows-setup.ps1
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-windows-setup.ps1 -Preset Minimal
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-windows-setup.ps1 -Preset LeaveDefaults
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-windows-setup.ps1 -SkipSoftware
# ::		powershell.exe -ExecutionPolicy Bypass -File .\rtd-oem-windows-setup.ps1 -Restart
# ::
# :: Presets:	Aggressive  Default. Removes consumer apps and disables non-essential noise.
# ::		Minimal     Keeps bundled apps but disables telemetry, ads, and suggestions.
# ::		LeaveDefaults  Leaves Windows settings unchanged while allowing selected software and tools to install.
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
    [ValidateSet("Aggressive", "Minimal", "LeaveDefaults")]
    [string]$Preset = "Aggressive",

    [switch]$Restart,

    [switch]$SkipSoftware,

    [switch]$SkipGuestTools,

    [switch]$ApplyDodSecureDefaults
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$Script:RestartRequired = $false
$Script:RtdRoot = "C:\RTD"
$Script:LogDir = [System.IO.Path]::Combine($Script:RtdRoot, "log")
$Script:SetupLog = "C:\setup.log"
$Script:ChocoExe = $null
$Script:SoftwareFailures = New-Object System.Collections.Generic.List[string]
$Script:WarningCount = 0
$Script:VirtualizationPlatform = $null
$Script:WindowsIdentity = $null
$Script:WallpaperUrl = "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/wallpaper/Wayland.jpg"
$Script:DodSecureDefaultsUrl = "https://raw.githubusercontent.com/simeononsecurity/Windows-Optimize-Harden-Debloat/refs/heads/master/sos-optimize-windows.ps1"
$Script:DefaultUserHiveName = "RTD_DefaultUser"
$Script:DefaultUserHiveRoot = "Registry::HKEY_USERS\$($Script:DefaultUserHiveName)"
$Script:DefaultUserHiveAvailable = $false
$Script:DefaultUserHiveMountedByScript = $false

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
        Add-Content -Path (Join-Path $Script:LogDir "windows-setup.log") -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
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

    Write-Host "RunTime Data Windows configuration requires administrative privileges. Relaunching elevated..."
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
    if ($SkipGuestTools) {
        $arguments += "-SkipGuestTools"
    }
    if ($ApplyDodSecureDefaults) {
        $arguments += "-ApplyDodSecureDefaults"
    }

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Return stable OS identity data without treating a marketing name as a feature
# switch. Tests may supply registry/CIM fixtures; production calls query Windows.
function Get-RtdWindowsIdentity {
    param(
        [hashtable]$CurrentVersion,
        [psobject]$OperatingSystem
    )

    if (-not $CurrentVersion) {
        $properties = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop
        $CurrentVersion = @{
            ProductName = [string]$properties.ProductName
            EditionID = [string]$properties.EditionID
            DisplayVersion = [string]$properties.DisplayVersion
            CurrentBuildNumber = [string]$properties.CurrentBuildNumber
            UBR = $properties.UBR
            InstallationType = [string]$properties.InstallationType
        }
    }
    if (-not $OperatingSystem) {
        $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    }

    $build = 0
    [void][int]::TryParse([string]$CurrentVersion.CurrentBuildNumber, [ref]$build)
    $installationType = [string]$CurrentVersion.InstallationType
    $productName = [string]$CurrentVersion.ProductName
    $family = "FutureOrUnknown"
    if ($installationType -match "Server") {
        $family = "WindowsServer"
    } elseif ($build -lt 10240) {
        $family = "LegacyWindows"
    } elseif ($build -lt 22000) {
        $family = "Windows10"
    } elseif ($productName -match "Windows 11" -or $productName -match "Windows 10") {
        # Some Windows 11 builds retain "Windows 10" in CurrentVersion.ProductName
        # for compatibility. Build 22000 remains the reliable family boundary.
        $family = "Windows11"
    }

    return [pscustomobject]@{
        ProductName = $productName
        EditionID = [string]$CurrentVersion.EditionID
        DisplayVersion = [string]$CurrentVersion.DisplayVersion
        InstallationType = $installationType
        Build = $build
        UBR = [int]$CurrentVersion.UBR
        Version = [string]$OperatingSystem.Version
        Architecture = [string]$OperatingSystem.OSArchitecture
        Caption = [string]$OperatingSystem.Caption
        Family = $family
        IsSupportedBaseline = $build -ge 10240
        IsFutureOrUnknown = $family -eq "FutureOrUnknown"
    }
}

# New local/domain profiles are copied from C:\Users\Default. Mount its registry
# hive for the duration of setup so every HKCU tweak can also be written to the
# profile template. HKEY_USERS\.DEFAULT is not the new-user template; it belongs
# to the logon/system desktop and must not be used as an HKCU substitute.
function Mount-RtdDefaultUserHive {
    $hiveFile = Join-Path $env:SystemDrive "Users\Default\NTUSER.DAT"
    try {
        if (-not (Test-Path -LiteralPath $hiveFile -PathType Leaf)) {
            throw "Default-user hive was not found at '$hiveFile'."
        }

        if (Test-Path $Script:DefaultUserHiveRoot) {
            $Script:DefaultUserHiveAvailable = $true
            Write-RtdLog "Using the already-mounted default-user registry hive."
            return
        }

        & reg.exe load "HKU\$($Script:DefaultUserHiveName)" $hiveFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "reg.exe could not load the default-user hive (exit code $LASTEXITCODE)."
        }

        $Script:DefaultUserHiveAvailable = $true
        $Script:DefaultUserHiveMountedByScript = $true
        Write-RtdLog "Default-user registry hive mounted; HKCU tweaks will also apply to future users." "OK"
    } catch {
        $Script:DefaultUserHiveAvailable = $false
        Write-RtdLog "Future-user defaults cannot be configured: $($_.Exception.Message)" "WARN"
    }
}

function Dismount-RtdDefaultUserHive {
    if (-not $Script:DefaultUserHiveMountedByScript) {
        return
    }

    $Script:DefaultUserHiveAvailable = $false
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    & reg.exe unload "HKU\$($Script:DefaultUserHiveName)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-RtdLog "Default-user registry hive could not be unloaded. Restart Windows before capturing the image." "WARN"
        return
    }

    $Script:DefaultUserHiveMountedByScript = $false
    Write-RtdLog "Default-user registry hive unloaded." "OK"
}

# Prepare the working folders, record exact OS identity, and apply shared
# personalization. Windows 10 and newer use one capability-driven path.
function Initialize-RtdWindowsConfig {
    Start-RtdElevated

    New-Item -Path $Script:RtdRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $Script:LogDir -ItemType Directory -Force | Out-Null
    New-Item -Path $Script:SetupLog -ItemType File -Force | Out-Null

    try {
        Start-Transcript -Path (Join-Path $Script:LogDir "windows-setup-transcript.log") -Append -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-RtdLog "Transcript logging could not be started: $($_.Exception.Message)" "WARN"
    }

    try {
        $Script:WindowsIdentity = Get-RtdWindowsIdentity
        $identity = $Script:WindowsIdentity
        Write-RtdLog "Detected Windows: product='$($identity.ProductName)'; caption='$($identity.Caption)'; edition='$($identity.EditionID)'; display version='$($identity.DisplayVersion)'; installation type='$($identity.InstallationType)'; build=$($identity.Build).$($identity.UBR); architecture='$($identity.Architecture)'; family='$($identity.Family)'."
        if (-not $identity.IsSupportedBaseline) {
            Write-RtdLog "Build $($identity.Build) predates the Windows 10 baseline. Setup will continue best-effort, but this OS is unsupported." "WARN"
        } elseif ($identity.IsFutureOrUnknown) {
            Write-RtdLog "This Windows release is newer than or outside the explicitly classified Windows families. Continuing with capability detection rather than falling back to a legacy script." "WARN"
        }
    } catch {
        Write-RtdLog "Windows identity detection failed: $($_.Exception.Message). Capability detection will continue." "WARN"
    }

    if ($Preset -eq "LeaveDefaults") {
        Write-RtdLog "Leave Defaults preset selected; wallpaper and default-profile customization were skipped."
    } else {
        Mount-RtdDefaultUserHive
        Set-RtdWindowsWallpaper
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

    $targetPaths = @($Path)
    if ($Path.StartsWith("HKCU:\", [System.StringComparison]::OrdinalIgnoreCase) -and
        $Script:DefaultUserHiveAvailable) {
        $targetPaths += "$($Script:DefaultUserHiveRoot)\$($Path.Substring(6))"
    }

    foreach ($targetPath in $targetPaths) {
        try {
            if (-not (Test-Path $targetPath)) {
                New-Item -Path $targetPath -Force | Out-Null
            }

            New-ItemProperty -Path $targetPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        } catch {
            Write-RtdLog "Registry write failed: $targetPath\$Name -> $Value ($($_.Exception.Message))" "WARN"
        }
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

    $targetPaths = @($Path)
    if ($Path.StartsWith("HKCU:\", [System.StringComparison]::OrdinalIgnoreCase) -and
        $Script:DefaultUserHiveAvailable) {
        $targetPaths += "$($Script:DefaultUserHiveRoot)\$($Path.Substring(6))"
    }

    foreach ($targetPath in $targetPaths) {
        try {
            if (Test-Path $targetPath) {
                Remove-ItemProperty -Path $targetPath -Name $Name -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-RtdLog "Registry value removal failed: $targetPath\$Name ($($_.Exception.Message))" "WARN"
        }
    }
}

# Download and validate the shared wallpaper independently of the bootstrap.
function Save-RtdWallpaper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $directory = Split-Path -Parent $Destination
    $temporaryPath = "$Destination.download"
    New-Item -Path $directory -ItemType Directory -Force | Out-Null
    Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    try {
        $cacheBuster = (Get-Date).ToUniversalTime().Ticks
        $url = "{0}?rtd_cache_bust={1}" -f $Script:WallpaperUrl, $cacheBuster
        Invoke-WebRequest -Uri $url -OutFile $temporaryPath -UseBasicParsing -ErrorAction Stop
        $file = Get-Item -LiteralPath $temporaryPath -ErrorAction Stop
        if ($file.Length -lt 10KB) {
            throw "Downloaded wallpaper is unexpectedly small ($($file.Length) bytes)."
        }
        $stream = [System.IO.File]::OpenRead($temporaryPath)
        try {
            $header = New-Object byte[] 3
            [void]$stream.Read($header, 0, $header.Length)
        } finally {
            $stream.Dispose()
        }
        if (-not ($header[0] -eq 0xFF -and $header[1] -eq 0xD8 -and $header[2] -eq 0xFF)) {
            throw "Downloaded wallpaper is not a valid JPEG file."
        }
        Move-Item -LiteralPath $temporaryPath -Destination $Destination -Force
        Write-RtdLog "Wallpaper downloaded to '$Destination' (SHA-256=$((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash))." "OK"
        return $true
    } catch {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        Write-RtdLog "Wallpaper download failed: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Set-RtdCurrentUserWallpaper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "Wallpaper" $Path "String"
        Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "WallpaperStyle" "10" "String"
        Set-RtdRegistryValue "HKCU:\Control Panel\Desktop" "TileWallpaper" "0" "String"
        if (-not ("RtdWallpaperNativeMethods" -as [type])) {
            Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class RtdWallpaperNativeMethods
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(int action, int parameter, string value, int flags);
}
"@
        }
        if (-not [RtdWallpaperNativeMethods]::SystemParametersInfo(20, 0, $Path, 3)) {
            throw "SystemParametersInfo failed with Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
        }
        Write-RtdLog "Current-user wallpaper applied for '$([Security.Principal.WindowsIdentity]::GetCurrent().Name)'." "OK"
    } catch {
        Write-RtdLog "Current-user wallpaper could not be applied: $($_.Exception.Message)" "WARN"
    }
}

function Set-RtdDefaultUserWallpaper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $desktopKey = "$($Script:DefaultUserHiveRoot)\Control Panel\Desktop"
    try {
        if (-not $Script:DefaultUserHiveAvailable) {
            throw "Default-user registry hive is unavailable."
        }

        New-Item -Path $desktopKey -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "Wallpaper" -Value $Path -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "WallpaperStyle" -Value "10" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "TileWallpaper" -Value "0" -PropertyType String -Force | Out-Null
        Remove-ItemProperty -Path $desktopKey -Name "TranscodedImageCache" -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $desktopKey -Name "TranscodedImageCount" -Force -ErrorAction SilentlyContinue
        $cachedWallpaper = Join-Path $env:SystemDrive "Users\Default\AppData\Roaming\Microsoft\Windows\Themes\TranscodedWallpaper"
        Remove-Item -LiteralPath $cachedWallpaper -Force -ErrorAction SilentlyContinue
        Write-RtdLog "Default-user wallpaper configured for accounts created after Sysprep/OOBE." "OK"
    } catch {
        Write-RtdLog "Default-user wallpaper could not be configured: $($_.Exception.Message)" "WARN"
    }
}

function Set-RtdWindowsWallpaper {
    $wallpaperPath = Join-Path (Join-Path $Script:RtdRoot "wallpaper") "Wayland.jpg"
    if ((Test-Path -LiteralPath $wallpaperPath -PathType Leaf) -or (Save-RtdWallpaper -Destination $wallpaperPath)) {
        Set-RtdCurrentUserWallpaper -Path $wallpaperPath
        Set-RtdDefaultUserWallpaper -Path $wallpaperPath
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
function Disable-RtdWindowsTelemetry {
    Write-RtdLog "Disabling Windows telemetry and feedback collection."

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
function Disable-RtdWindowsSuggestionsAndAds {
    Write-RtdLog "Disabling Windows suggestions, ads, consumer content, and web search noise."

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
function Disable-RtdWindowsCopilotWidgetsChat {
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
function Disable-RtdWindowsBackgroundApps {
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
function Disable-RtdWindowsGaming {
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
function Disable-RtdWindowsOneDrive {
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
function Set-RtdWindowsPerformanceUi {
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

# Preserve the safe, still-useful parts of the former Windows 10 baseline.
# Every OS component is checked before invocation so newer Windows releases can
# continue without requiring another version-named script.
function Set-RtdWindowsCompatibilityBaseline {
    Write-RtdLog "Applying capability-gated Windows compatibility and security defaults."

    # SMB1 and LLMNR are legacy discovery/protocol surfaces. Keep SMB2/3 and the
    # firewall enabled; the former script's SMB-server and firewall changes are
    # intentionally not carried forward.
    try {
        if (Get-Command "Get-WindowsOptionalFeature" -ErrorAction SilentlyContinue) {
            $smb1 = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction SilentlyContinue
            if ($smb1 -and $smb1.State -eq "Enabled") {
                Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction Stop | Out-Null
                $Script:RestartRequired = $true
                Write-RtdLog "SMB1 optional feature disabled." "OK"
            } elseif ($smb1) {
                Write-RtdLog "SMB1 optional feature is already disabled or absent." "OK"
            }
        } elseif (Get-Command "Set-SmbServerConfiguration" -ErrorAction SilentlyContinue) {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop | Out-Null
            Write-RtdLog "SMB1 server protocol disabled through the SMB cmdlet." "OK"
        } else {
            Write-RtdLog "SMB1 management capability is unavailable; no SMB change was attempted."
        }
    } catch {
        Write-RtdLog "SMB1 could not be disabled: $($_.Exception.Message)" "WARN"
    }
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" 0

    # Retain remote-assistance, shared-experience, and removable-media hardening
    # without enabling/disabling Remote Desktop itself.
    Set-RtdRegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableCdp" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 1
    Set-RtdRegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255

    # Preserve the useful end-user defaults from the Windows 10 worker.
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
    Set-RtdRegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
    Set-RtdRegistryValue "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String"
    Set-RtdRegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" "StartupPage" 1
    Set-RtdRegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" "AllItemsIconView" 1
    Set-RtdRegistryValue "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" "InitialKeyboardIndicators" "2147483650" "String"

    # Active-hours values are used only when the Windows Update UX key exists.
    $updateUxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (Test-Path $updateUxPath) {
        Set-RtdRegistryValue $updateUxPath "ActiveHoursStart" 8
        Set-RtdRegistryValue $updateUxPath "ActiveHoursEnd" 2
    } else {
        Write-RtdLog "Windows Update UX active-hours capability is absent; active hours were not changed."
    }

    # Set connected non-domain networks private when the networking cmdlets are
    # available. Domain-authenticated profiles retain their managed category.
    if ((Get-Command "Get-NetConnectionProfile" -ErrorAction SilentlyContinue) -and
        (Get-Command "Set-NetConnectionProfile" -ErrorAction SilentlyContinue)) {
        try {
            $profiles = Get-NetConnectionProfile -ErrorAction Stop |
                Where-Object { $_.NetworkCategory -ne "DomainAuthenticated" }
            foreach ($profile in $profiles) {
                Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
                Write-RtdLog "Network profile '$($profile.Name)' set to Private." "OK"
            }
        } catch {
            Write-RtdLog "Network profiles could not be set to Private: $($_.Exception.Message)" "WARN"
        }
    } else {
        Write-RtdLog "Network profile cmdlets are unavailable; network category was not changed."
    }
}

# Edge is left installed because Windows components depend on it, but first-run,
# sidebar, shopping, suggestions, feedback, and diagnostic reporting are reduced.
function Set-RtdWindowsEdgePolicy {
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
function Optimize-RtdWindowsServices {
    Write-RtdLog "Optimizing non-essential Windows services."

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

# Curated consumer AppX package list for Windows. The list avoids core
# platform components such as Store dependencies, WebView2, Defender, Update,
# networking, and management tooling.
function Remove-RtdWindowsBloatApps {
    Write-RtdLog "Removing Windows consumer AppX packages."

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
function Resolve-RtdSecureDownloadUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.Method = "HEAD"
        $request.AllowAutoRedirect = $false
        $response = $request.GetResponse()
        try {
            $location = $response.Headers["Location"]
        } finally {
            $response.Close()
        }
        if (-not $location) {
            return $Url
        }

        $resolved = (New-Object System.Uri -ArgumentList ([System.Uri]$Url), $location).AbsoluteUri
        $resolvedUri = [System.Uri]$resolved
        if ($resolvedUri.Host -eq "fedorapeople.org" -and $resolvedUri.Scheme -eq "http") {
            $resolved = "https://{0}{1}" -f $resolvedUri.Host, $resolvedUri.PathAndQuery
        }
        return $resolved
    } catch {
        Write-RtdLog "Could not resolve secure redirect for ${Url}: $($_.Exception.Message)" "WARN"
        return $Url
    }
}

function Get-RtdLatestVirtioGuestTools {
    $indexCandidates = @(
        "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D",
        "https://fedora-virt.repo.nfrance.com/virtio-win/direct-downloads/archive-virtio/"
    )

    $artifactTemplates = @(
        "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/{0}/virtio-win-guest-tools.exe",
        "https://fedora-virt.repo.nfrance.com/virtio-win/direct-downloads/archive-virtio/{0}/virtio-win-guest-tools.exe",
        "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
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
            Write-RtdLog "Could not inspect virtio-win archive index ${indexUrl}: $($_.Exception.Message)" "WARN"
        }
    }

    $latestRelease = $releases |
        Sort-Object Major, Minor, Patch, Revision -Descending |
        Select-Object -First 1

    $qemuAgentUrl = Resolve-RtdSecureDownloadUrl "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-qemu-ga/qemu-ga-x86_64.msi"
    if ($latestRelease) {
        $url = $artifactTemplates[0] -f $latestRelease.Version
        Write-RtdLog "Selected virtio guest-tools release $($latestRelease.Version) at exact HTTPS archive URL $url."
        return [pscustomobject]@{
            Version = $latestRelease.Version
            Url = $url
            MsiUrl = ($url -replace 'virtio-win-guest-tools\.exe$', 'virtio-win-gt-x64.msi')
            QemuAgentUrl = $qemuAgentUrl
        }
    }

    $fallbackVersion = if ($latestRelease) { $latestRelease.Version } else { "latest-virtio" }
    $fallbackUrl = Resolve-RtdSecureDownloadUrl $artifactTemplates[2]
    return [pscustomobject]@{
        Version = $fallbackVersion
        Url = $fallbackUrl
        MsiUrl = ($fallbackUrl -replace 'virtio-win-guest-tools\.exe$', 'virtio-win-gt-x64.msi')
        QemuAgentUrl = $qemuAgentUrl
    }
}

function Assert-RtdInstallerFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file.Length -lt 1MB) {
        throw "The downloaded installer is unexpectedly small ($($file.Length) bytes)."
    }

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $header = New-Object byte[] 8
        $bytesRead = $stream.Read($header, 0, $header.Length)
    } finally {
        $stream.Dispose()
    }
    if ($bytesRead -lt 8) {
        throw "The downloaded installer has an incomplete file header."
    }

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($extension -eq ".exe" -and -not ($header[0] -eq 0x4D -and $header[1] -eq 0x5A)) {
        throw "The downloaded EXE does not have a valid Windows PE header."
    }
    if ($extension -eq ".msi") {
        [byte[]]$msiHeader = @(0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1)
        for ($index = 0; $index -lt $msiHeader.Length; $index++) {
            if ($header[$index] -ne $msiHeader[$index]) {
                throw "The downloaded MSI does not have a valid Windows Installer compound-file header."
            }
        }
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -eq "HashMismatch") {
        throw "Authenticode reports a hash mismatch; the installer is corrupted."
    }
    $signer = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { "unsigned outer installer" }
    if (-not $signature.SignerCertificate) {
        Write-RtdLog "Installer '$Path' has no outer Authenticode signature; binary structure and HTTP content length will be used for transport-integrity validation."
    }
    Write-RtdLog "Validated installer '$Path': SHA-256=$((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash); signer=$signer; signature status=$($signature.Status)." "OK"
}

function Save-RtdInstallerDownload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $destinationDirectory = Split-Path -Parent $Destination
    $destinationName = [System.IO.Path]::GetFileNameWithoutExtension($Destination)
    $destinationExtension = [System.IO.Path]::GetExtension($Destination)
    $partialPath = Join-Path $destinationDirectory ("{0}.partial{1}" -f $destinationName, $destinationExtension)
    $failures = New-Object System.Collections.Generic.List[string]
    $downloadMethods = @("BITS", "curl", "WebClient")
    $expectedLength = 0
    try {
        $sizeRequest = [System.Net.HttpWebRequest]::Create($Url)
        $sizeRequest.Method = "HEAD"
        $sizeResponse = $sizeRequest.GetResponse()
        try {
            $expectedLength = [int64]$sizeResponse.ContentLength
        } finally {
            $sizeResponse.Close()
        }
        if ($expectedLength -gt 0) {
            Write-RtdLog "Remote installer content length is $expectedLength bytes."
        }
    } catch {
        Write-RtdLog "Remote installer size could not be determined before download: $($_.Exception.Message)" "WARN"
    }

    foreach ($method in $downloadMethods) {
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        try {
            Write-RtdLog "Downloading '$Url' with $method."
            switch ($method) {
                "BITS" {
                    Import-Module BitsTransfer -ErrorAction Stop
                    Start-BitsTransfer -Source $Url -Destination $partialPath -ErrorAction Stop
                }
                "curl" {
                    $curl = Join-Path $env:SystemRoot "System32\curl.exe"
                    if (-not (Test-Path -LiteralPath $curl -PathType Leaf)) {
                        throw "curl.exe is unavailable."
                    }
                    & $curl --fail --location --retry 3 --retry-delay 2 --output $partialPath $Url
                    if ($LASTEXITCODE -ne 0) {
                        throw "curl.exe returned exit code $LASTEXITCODE."
                    }
                }
                "WebClient" {
                    $client = New-Object System.Net.WebClient
                    try {
                        $client.Headers["Cache-Control"] = "no-cache"
                        $client.DownloadFile($Url, $partialPath)
                    } finally {
                        $client.Dispose()
                    }
                }
            }

            Assert-RtdInstallerFile -Path $partialPath
            $actualLength = (Get-Item -LiteralPath $partialPath).Length
            if ($expectedLength -gt 0 -and $actualLength -ne $expectedLength) {
                throw "Downloaded length $actualLength does not match the server content length $expectedLength."
            }
            Move-Item -LiteralPath $partialPath -Destination $Destination -Force
            Write-RtdLog "Installer download completed successfully with $method." "OK"
            return
        } catch {
            $failure = "${method}: $($_.Exception.Message)"
            $failures.Add($failure)
            Write-RtdLog "Installer download attempt failed using ${failure}" "WARN"
        }
    }

    Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
    throw "All installer download methods failed for '$Url': $($failures -join ' | ')"
}

function Invoke-RtdMsiInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    Write-RtdLog "Installing $DisplayName from '$InstallerPath'."
    $arguments = @(
        "/i", ('"{0}"' -f $InstallerPath),
        "/qn", "/norestart",
        "/L*v", ('"{0}"' -f $LogPath)
    )
    $process = Start-Process -FilePath (Join-Path $env:SystemRoot "System32\msiexec.exe") -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -notin @(0, 1638, 1641, 3010)) {
        throw "$DisplayName installer returned exit code $($process.ExitCode). Review '$LogPath'."
    }
    if ($process.ExitCode -in @(1641, 3010)) {
        $Script:RestartRequired = $true
    }
    Write-RtdLog "$DisplayName installation completed with exit code $($process.ExitCode)." "OK"
}

function Get-RtdKvmGuestComponentStatus {
    $qemuService = Get-Service -Name "qemu-ga" -ErrorAction SilentlyContinue
    $spiceService = Get-Service -Name "vdservice" -ErrorAction SilentlyContinue
    return [pscustomobject]@{
        QemuAgentInstalled = $null -ne $qemuService
        SpiceAgentInstalled = $null -ne $spiceService
        QemuAgentStatus = if ($qemuService) { [string]$qemuService.Status } else { "NotInstalled" }
        SpiceAgentStatus = if ($spiceService) { [string]$spiceService.Status } else { "NotInstalled" }
    }
}

function Start-RtdKvmGuestServices {
    foreach ($serviceName in @("qemu-ga", "vdservice")) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            continue
        }
        try {
            Set-Service -Name $serviceName -StartupType Automatic -ErrorAction Stop
            if ($service.Status -ne "Running") {
                Start-Service -Name $serviceName -ErrorAction Stop
            }
            Write-RtdLog "KVM guest service '$serviceName' is configured for automatic startup." "OK"
        } catch {
            Write-RtdLog "KVM guest service '$serviceName' could not be started: $($_.Exception.Message)" "WARN"
        }
    }
}

# Use the upstream guest-tools bundle for KVM/QEMU guests instead of depending
# on Chocolatey packages that may lag behind the virtio driver release cadence.
function Install-RtdVirtioGuestTools {
    $download = Get-RtdLatestVirtioGuestTools
    $cacheDirectory = Join-Path $Script:RtdRoot "cache"
    $installerPath = Join-Path $cacheDirectory "virtio-win-guest-tools.exe"
    $bundleMsiPath = Join-Path $cacheDirectory "virtio-win-gt-x64.msi"
    $qemuAgentMsiPath = Join-Path $cacheDirectory "qemu-ga-x86_64.msi"
    $bundleInstalled = $false

    try {
        New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null
        Write-RtdLog "Downloading virtio guest tools release $($download.Version) from $($download.Url)."
        Save-RtdInstallerDownload -Url $download.Url -Destination $installerPath

        $process = Start-Process -FilePath $installerPath -ArgumentList @("/quiet", "/norestart", "/log", (Join-Path $Script:LogDir "virtio-bundle.log")) -Wait -PassThru
        if ($process.ExitCode -in @(0, 1638, 1641, 3010)) {
            Write-RtdLog "virtio guest tools installed successfully from release $($download.Version) (exit code $($process.ExitCode))." "OK"
            $bundleInstalled = $true
            $Script:RestartRequired = $true
            if ($process.ExitCode -in @(1641, 3010)) {
                $Script:RestartRequired = $true
            }
        } else {
            Write-RtdLog "virtio guest-tools bundle returned exit code $($process.ExitCode); the MSI fallback will be attempted." "WARN"
        }
    } catch {
        Write-RtdLog "virtio guest-tools bundle attempt failed: $($_.Exception.Message). The MSI fallback will be attempted." "WARN"
    }

    Start-Sleep -Seconds 2
    $status = Get-RtdKvmGuestComponentStatus
    if (-not $bundleInstalled -or -not $status.QemuAgentInstalled -or -not $status.SpiceAgentInstalled) {
        try {
            Write-RtdLog "Guest component verification requires the x64 virtio MSI fallback (QEMU agent: $($status.QemuAgentStatus); SPICE agent: $($status.SpiceAgentStatus))." "WARN"
            Save-RtdInstallerDownload -Url $download.MsiUrl -Destination $bundleMsiPath
            Invoke-RtdMsiInstall -InstallerPath $bundleMsiPath -LogPath (Join-Path $Script:LogDir "virtio-msi.log") -DisplayName "VirtIO/SPICE guest tools"
            $Script:RestartRequired = $true
        } catch {
            Write-RtdLog "VirtIO/SPICE MSI fallback failed: $($_.Exception.Message)" "WARN"
        }
    }

    $status = Get-RtdKvmGuestComponentStatus
    if (-not $status.QemuAgentInstalled) {
        try {
            Write-RtdLog "QEMU Guest Agent service is missing; installing the current standalone Fedora QEMU agent."
            Save-RtdInstallerDownload -Url $download.QemuAgentUrl -Destination $qemuAgentMsiPath
            Invoke-RtdMsiInstall -InstallerPath $qemuAgentMsiPath -LogPath (Join-Path $Script:LogDir "qemu-ga-msi.log") -DisplayName "QEMU Guest Agent"
        } catch {
            Write-RtdLog "Standalone QEMU Guest Agent installation failed: $($_.Exception.Message)" "WARN"
        }
    }

    Start-RtdKvmGuestServices
    $status = Get-RtdKvmGuestComponentStatus
    Write-RtdLog "KVM guest component status: QEMU Guest Agent=$($status.QemuAgentStatus); SPICE agent=$($status.SpiceAgentStatus)."

    if (-not $status.QemuAgentInstalled -or -not $status.SpiceAgentInstalled) {
        $message = "KVM guest integration is incomplete after installation attempts (QEMU Guest Agent=$($status.QemuAgentStatus); SPICE agent=$($status.SpiceAgentStatus)). Review virtio-bundle.log, virtio-msi.log, and qemu-ga-msi.log in $($Script:LogDir)."
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        return $false
    }

    Write-RtdLog "VirtIO drivers, QEMU Guest Agent, and SPICE guest agent are installed." "OK"
    return $true
}

# Windows includes Hyper-V integration components. Other detected hypervisors
# receive the same guest utilities requested by the Windows 10 configuration.
function Install-RtdVirtualizationGuestTools {
    $platform = Get-RtdVirtualizationPlatform
    $Script:VirtualizationPlatform = $platform

    switch ($platform) {
        "vmware" {
            if (Initialize-RtdChocolatey) {
                Install-RtdChocolateyPackage "vmware-tools" "VMware Tools" | Out-Null
            }
        }
        "virtualbox" {
            if (Initialize-RtdChocolatey) {
                Install-RtdChocolateyPackage "virtualbox-guest-additions-guest.install" "VirtualBox Guest Additions" | Out-Null
            }
        }
        "kvm" {
            Set-RtdRegistryValue "HKLM:\Software\Policies\Microsoft\Windows NT\Driver Signing" "BehaviorOnFailedVerify" 1
            Install-RtdVirtioGuestTools | Out-Null
        }
        "hyperv" {
            Write-RtdLog "Hyper-V guest detected; integration services are built into Windows." "OK"
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
# current Windows-oriented recommended profile. Verify the signed executable
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
# feature. Retain that behavior when the feature exists on the Windows image.
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

# Install the standard Windows application set. Optional bundles such as games,
# graphics tools, PDF tools, and LibreOffice remain excluded.
function Install-RtdWindowsSoftware {
    Write-RtdLog "Starting standard RunTime Data software deployment."

    if (Initialize-RtdChocolatey) {
        $software = @(
            @{ Package = "chocolatey-core.extension"; Name = "Chocolatey Core Extension"; Parameters = @() },
            @{ Package = "chocolateygui"; Name = "Chocolatey GUI"; Parameters = @() },
            @{ Package = "7zip"; Name = "7-Zip"; Parameters = @() },
            @{ Package = "vscode"; Name = "Visual Studio Code"; Parameters = @() },
            @{ Package = "filezilla"; Name = "FileZilla"; Parameters = @() },
            @{ Package = "putty"; Name = "PuTTY"; Parameters = @() },
            @{ Package = "rustdesk"; Name = "RustDesk remote desktop support"; Parameters = @() },
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

    if ($Preset -eq "LeaveDefaults") {
        Write-RtdLog "Leave Defaults preset selected; O&O ShutUp10++ and optional-feature changes were skipped."
    } else {
        Install-RtdShutUp10 | Out-Null
        Enable-RtdWindowsMediaPlayer
    }

    if ($Script:SoftwareFailures.Count -gt 0) {
        Write-RtdLog "Software deployment completed with $($Script:SoftwareFailures.Count) failure(s)." "WARN"
        foreach ($failure in $Script:SoftwareFailures) {
            Write-RtdLog "Software deployment issue: $failure" "WARN"
        }
    } else {
        Write-RtdLog "Standard RTD software deployment completed successfully." "OK"
    }
}

# The password-protected KMS archive is expanded only after the standard
# application phase has installed 7-Zip. Activation itself remains an explicit
# frontend choice and is performed after this worker exits.
function Expand-RtdKmsArchive {
    $coreDirectory = Join-Path $Script:RtdRoot "core"
    $archivePath = Join-Path $coreDirectory "_KMS.zip"
    if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
        Write-RtdLog "KMS archive was not present at '$archivePath'; extraction was skipped."
        return $true
    }

    $sevenZipCandidates = @()
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) {
            $sevenZipCandidates += Join-Path $root "7-Zip\7z.exe"
        }
    }
    if ($env:ChocolateyInstall) {
        $sevenZipCandidates += Join-Path $env:ChocolateyInstall "bin\7z.exe"
    }
    $sevenZipCandidates = $sevenZipCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    $sevenZip = $sevenZipCandidates | Select-Object -First 1
    if (-not $sevenZip) {
        $sevenZipCommand = Get-Command "7z.exe" -ErrorAction SilentlyContinue
        if ($sevenZipCommand) {
            $sevenZip = $sevenZipCommand.Source
        }
    }

    if (-not $sevenZip) {
        Write-RtdLog "KMS archive could not be extracted because 7-Zip is unavailable after application installation." "WARN"
        return $false
    }

    try {
        $arguments = @(
            "x",
            $archivePath,
            "-o$coreDirectory",
            "-pepUTtqAdn2AVEbj9fzy9",
            "-y"
        )
        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "7-Zip exited with code $($process.ExitCode)."
        }

        $kmsScript = Join-Path $coreDirectory "KMS.cmd"
        if (-not (Test-Path -LiteralPath $kmsScript -PathType Leaf)) {
            throw "The archive was extracted, but KMS.cmd was not found at '$kmsScript'."
        }
        Write-RtdLog "KMS activation files were extracted successfully." "OK"
        return $true
    } catch {
        Write-RtdLog "KMS archive extraction failed: $($_.Exception.Message)" "WARN"
        return $false
    }
}

# Reject incomplete or syntactically invalid hardening scripts before they are
# executed. This is especially important for cached files left by an interrupted
# download.
function Test-RtdPowerShellScriptSyntax {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    try {
        if ((Get-Item -LiteralPath $Path -ErrorAction Stop).Length -eq 0) {
            return $false
        }
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $Path,
            [ref]$tokens,
            [ref]$parseErrors
        ) | Out-Null
        if ($parseErrors.Count -gt 0) {
            $details = $parseErrors | ForEach-Object {
                "line $($_.Extent.StartLineNumber): $($_.Message)"
            }
            Write-RtdLog "PowerShell syntax validation failed for '$Path': $($details -join '; ')" "WARN"
            return $false
        }
        return $true
    } catch {
        Write-RtdLog "Could not validate PowerShell script '$Path': $($_.Exception.Message)" "WARN"
        return $false
    }
}

# Prefer a script shipped with RTD. If it is unavailable, download the current
# upstream version into the cache and retain a previously validated cache copy
# as an offline fallback.
function Resolve-RtdDodSecureDefaultsScript {
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    $bundledCandidates = @(
        (Join-Path $PSScriptRoot "_secure_windows.ps1"),
        (Join-Path $repositoryRoot "modules\windows.mod\_secure_windows.ps1"),
        "C:\RTD\core\_secure_windows.ps1",
        "C:\RTD\modules\windows.mod\_secure_windows.ps1"
    )

    foreach ($candidate in $bundledCandidates | Select-Object -Unique) {
        if (Test-RtdPowerShellScriptSyntax -Path $candidate) {
            Write-RtdLog "Using bundled DOD secure-defaults script: $candidate"
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $cacheDirectory = Join-Path $Script:RtdRoot "cache"
    $cachePath = Join-Path $cacheDirectory "_secure_windows.ps1"
    $temporaryPath = "$cachePath.download"
    New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null

    try {
        [System.Net.ServicePointManager]::SecurityProtocol =
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        $downloadUrl = "{0}?rtd_cache_bust={1}" -f $Script:DodSecureDefaultsUrl, (Get-Date).ToUniversalTime().Ticks
        $headers = @{
            "Cache-Control" = "no-cache, no-store"
            "Pragma" = "no-cache"
        }
        Write-RtdLog "Downloading the current DOD secure-defaults script from its upstream project."
        Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $temporaryPath -UseBasicParsing -ErrorAction Stop
        if (-not (Test-RtdPowerShellScriptSyntax -Path $temporaryPath)) {
            throw "The downloaded hardening script failed validation."
        }
        Move-Item -LiteralPath $temporaryPath -Destination $cachePath -Force
        return $cachePath
    } catch {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        Write-RtdLog "Could not download the current DOD secure-defaults script: $($_.Exception.Message)" "WARN"
        if (Test-RtdPowerShellScriptSyntax -Path $cachePath) {
            Write-RtdLog "Using the previously validated cached DOD secure-defaults script: $cachePath" "WARN"
            return (Resolve-Path -LiteralPath $cachePath).Path
        }
        throw "No valid local or downloadable DOD secure-defaults script is available."
    }
}

# Run the third-party hardening script in a child PowerShell process. Its use of
# exit or terminating errors therefore cannot abort the unified RTD setup worker.
function Invoke-RtdDodSecureDefaults {
    Write-RtdLog "Applying DOD Secure Defaults. This operation can take a significant amount of time."
    try {
        $scriptPath = Resolve-RtdDodSecureDefaultsScript
        $powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        if (-not (Test-Path -LiteralPath $powershellExe -PathType Leaf)) {
            $powershellExe = "powershell.exe"
        }

        & $powershellExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $scriptPath 2>&1 |
            ForEach-Object {
                if ($null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_)) {
                    Write-RtdLog "[DOD] $_"
                }
            }
        $hardeningExitCode = $LASTEXITCODE
        if ($hardeningExitCode -ne 0) {
            throw "The DOD secure-defaults script exited with code $hardeningExitCode."
        }

        $Script:RestartRequired = $true
        Write-RtdLog "DOD Secure Defaults were applied successfully." "OK"
        return $true
    } catch {
        $message = "DOD Secure Defaults could not be fully applied: $($_.Exception.Message)"
        $Script:SoftwareFailures.Add($message)
        Write-RtdLog $message "ERROR"
        Write-RtdLog "Review C:\RTD\log\windows-setup.log, confirm internet access, and rerun the setup with 'Apply DOD Secure Defaults' selected." "WARN"
        return $false
    }
}

# Minimal keeps Windows app payloads intact while reducing telemetry, ads,
# background app behavior, gaming overlays, and noisy shell/Edge defaults.
function Run-RtdWindowsMinimal {
    Set-RtdWindowsCompatibilityBaseline
    Disable-RtdWindowsTelemetry
    Disable-RtdWindowsSuggestionsAndAds
    Disable-RtdWindowsCopilotWidgetsChat
    Disable-RtdWindowsBackgroundApps
    Disable-RtdWindowsGaming
    Set-RtdWindowsPerformanceUi
    Set-RtdWindowsEdgePolicy
}

# Aggressive starts with Minimal, then removes OneDrive, tunes services, and
# removes consumer AppX payloads for a cleaner VM/VDI template.
function Run-RtdWindowsAggressive {
    Run-RtdWindowsMinimal
    Disable-RtdWindowsOneDrive
    Optimize-RtdWindowsServices
    Remove-RtdWindowsBloatApps
}

# Stop transcript logging and optionally restart. AppX removal and service
# changes often need a reboot before the final user experience is accurate.
function Complete-RtdWindowsConfig {
    Write-RtdStep "complete" "start"
    Dismount-RtdDefaultUserHive
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
Initialize-RtdWindowsConfig
Write-RtdStep "initialize" "done"

# Dispatch the selected preset after initialization so logging, elevation, and
# build checks are complete before any system changes are attempted.
if ($Preset -eq "LeaveDefaults") {
    Write-RtdLog "Leave Defaults preset selected; Windows tuning and optimization were skipped."
    Write-RtdStep "tuning" "skipped"
} else {
    Write-RtdStep "tuning" "start"
    switch ($Preset) {
        "Minimal" {
            Write-RtdLog "Running Windows Minimal preset."
            Run-RtdWindowsMinimal
        }
        default {
            Write-RtdLog "Running Windows Aggressive preset."
            Run-RtdWindowsAggressive
        }
    }
    Write-RtdStep "tuning" "done"
}

Write-RtdStep "software" "start"
if ($SkipGuestTools) {
    Write-RtdLog "Virtual-machine guest-tool installation was skipped because -SkipGuestTools was specified."
} else {
    Write-RtdLog "Installing virtualization guest tools before the standard application set."
    Install-RtdVirtualizationGuestTools
}

if ($SkipSoftware) {
    Write-RtdLog "Standard application deployment was skipped because -SkipSoftware was specified."
} else {
    Install-RtdWindowsSoftware
}

Expand-RtdKmsArchive | Out-Null

if ($Script:SoftwareFailures.Count -gt 0) {
    Write-RtdStep "software" "warning"
} else {
    Write-RtdStep "software" "done"
}

if ($ApplyDodSecureDefaults) {
    Invoke-RtdDodSecureDefaults | Out-Null
}

Complete-RtdWindowsConfig
