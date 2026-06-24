# RunTime Data Windows Setup graphical launcher
#
# This WPF frontend keeps the configuration worker usable from a terminal while
# providing an elevated, splash-style progress experience for interactive runs.

[CmdletBinding()]
param(
    [ValidateSet("Aggressive", "Minimal")]
    [string]$Preset = "Aggressive",

    [switch]$SkipSoftware,

    [switch]$SkipGuestTools,

    [switch]$Restart,

    [switch]$ApplyDodSecureDefaults,

    [switch]$AutoStart,

    [string]$WorkerPath
)

$ErrorActionPreference = "Stop"
$Script:WorkerProcess = $null
$Script:WorkerRunning = $false
$Script:SysprepInProgress = $false
$Script:CompletedWithWarnings = $false
$Script:AutoStartTimer = $null
$Script:AutoStartRemainingSeconds = 300
$Script:LineQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$Script:WorkerUrl = "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/rtd-oem-windows-setup.ps1"
$Script:BannerUrl = "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/Media_files/rtd-bootstrap-gui-banner.png"
$Script:FrontendLog = "C:\RTD\log\windows-setup-splash.log"

function Test-SetupAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SetupVirtualMachine {
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
        $baseBoard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue
        $fingerprint = @(
            $computerSystem.Manufacturer,
            $computerSystem.Model,
            $bios.Manufacturer,
            ($bios.SMBIOSBIOSVersion -join " "),
            $bios.Version,
            $baseBoard.Manufacturer,
            $baseBoard.Product
        ) | Where-Object { $_ -and $_.ToString().Trim() }

        return (($fingerprint -join " ") -match "Microsoft Corporation.*Virtual|Hyper-V|VMware|VirtualBox|Oracle|QEMU|KVM|Red Hat|RHV|oVirt|Bochs|Proxmox|Xen")
    } catch {
        return $false
    }
}

function Start-SetupElevated {
    if (Test-SetupAdministrator) {
        return
    }

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-STA",
        "-File", ('"{0}"' -f $PSCommandPath),
        "-Preset", $Preset
    )
    if ($SkipSoftware) {
        $arguments += "-SkipSoftware"
    }
    if ($SkipGuestTools) {
        $arguments += "-SkipGuestTools"
    }
    if ($Restart) {
        $arguments += "-Restart"
    }
    if ($ApplyDodSecureDefaults) {
        $arguments += "-ApplyDodSecureDefaults"
    }
    if ($AutoStart) {
        $arguments += "-AutoStart"
    }
    if ($WorkerPath) {
        $arguments += @("-WorkerPath", ('"{0}"' -f $WorkerPath))
    }

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show(
            "Administrative access is required to configure Windows.`n`n$($_.Exception.Message)",
            "RunTime Data Windows Setup",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    exit
}

function Initialize-SetupTransportSecurity {
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}

function Assert-SetupPowerShellSyntax {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

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
        throw "PowerShell syntax validation failed for '$Path': $($details -join '; ')"
    }
}

function Resolve-SetupWorker {
    if ($WorkerPath) {
        if (Test-Path -LiteralPath $WorkerPath -PathType Leaf) {
            Assert-SetupPowerShellSyntax -Path $WorkerPath
            return (Resolve-Path -LiteralPath $WorkerPath).Path
        }
        throw "The explicitly requested configuration script was not found: $WorkerPath"
    }

    $cacheDirectory = "C:\RTD\cache"
    $downloadPath = Join-Path $cacheDirectory "rtd-oem-windows-setup.ps1"
    $siblingWorker = Join-Path $PSScriptRoot "rtd-oem-windows-setup.ps1"
    $resolvedScriptDirectory = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd("\")
    $resolvedCacheDirectory = [System.IO.Path]::GetFullPath($cacheDirectory).TrimEnd("\")

    # Trust a worker distributed beside the frontend unless both files are in
    # the download cache. Cached workers are refreshed below to prevent stale
    # or partially downloaded scripts from being reused indefinitely.
    $bundledCandidates = @()
    if ($resolvedScriptDirectory -ne $resolvedCacheDirectory) {
        $bundledCandidates += $siblingWorker
    }
    $bundledCandidates += "C:\RTD\core\rtd-oem-windows-setup.ps1"

    foreach ($candidate in $bundledCandidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            try {
                Assert-SetupPowerShellSyntax -Path $candidate
                return (Resolve-Path -LiteralPath $candidate).Path
            } catch {
                # Try the downloadable worker when a bundled copy is invalid.
            }
        }
    }

    New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null
    $temporaryPath = "$downloadPath.download"
    try {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        $cacheBuster = (Get-Date).ToUniversalTime().Ticks
        $downloadUrl = "{0}?rtd_cache_bust={1}" -f $Script:WorkerUrl, $cacheBuster
        $requestHeaders = @{
            "Cache-Control" = "no-cache, no-store"
            "Pragma" = "no-cache"
        }
        Invoke-WebRequest -Uri $downloadUrl -Headers $requestHeaders -OutFile $temporaryPath -UseBasicParsing -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $temporaryPath -PathType Leaf) -or (Get-Item -LiteralPath $temporaryPath).Length -eq 0) {
            throw "The downloaded configuration script is empty."
        }
        Assert-SetupPowerShellSyntax -Path $temporaryPath
        Move-Item -LiteralPath $temporaryPath -Destination $downloadPath -Force
        return $downloadPath
    } catch {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $downloadPath -PathType Leaf) {
            Assert-SetupPowerShellSyntax -Path $downloadPath
            return (Resolve-Path -LiteralPath $downloadPath).Path
        }
        throw
    }
}

function Resolve-SetupBanner {
    $localBanner = Join-Path $PSScriptRoot "Media_files\rtd-bootstrap-gui-banner.png"
    if (Test-Path -LiteralPath $localBanner -PathType Leaf) {
        return (Resolve-Path -LiteralPath $localBanner).Path
    }

    try {
        $cacheDirectory = "C:\RTD\cache"
        $downloadPath = Join-Path $cacheDirectory "rtd-bootstrap-gui-banner.png"
        New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null
        Invoke-WebRequest -Uri $Script:BannerUrl -OutFile $downloadPath -UseBasicParsing
        return $downloadPath
    } catch {
        return $null
    }
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -TypeDefinition @"
using System.Collections.Concurrent;
using System.Diagnostics;

public static class SetupOutputBridge
{
    public static void Attach(Process process, ConcurrentQueue<string> queue)
    {
        process.OutputDataReceived += (sender, args) =>
        {
            if (args.Data != null) queue.Enqueue(args.Data);
        };
        process.ErrorDataReceived += (sender, args) =>
        {
            if (args.Data != null) queue.Enqueue("ERROR: " + args.Data);
        };
    }
}
"@
Start-SetupElevated
Initialize-SetupTransportSecurity

try {
    $Script:ResolvedWorker = Resolve-SetupWorker
} catch {
    [System.Windows.MessageBox]::Show(
        "The Windows configuration script could not be located or downloaded.`n`n$($_.Exception.Message)",
        "RunTime Data Windows Setup",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}
$Script:ResolvedBanner = Resolve-SetupBanner

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RunTime Data Windows Setup" Width="1000" Height="700" MinWidth="900" MinHeight="640"
        WindowStartupLocation="CenterScreen" WindowState="Maximized" ResizeMode="CanResize"
        Background="#07111F" FontFamily="Segoe UI" Foreground="#EAF3FF">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="24,11"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#D7E7FA"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,3,0,3"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="8,4"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="166"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="62"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" ClipToBounds="True">
            <Border x:Name="BannerFallback" Background="#0B2A4A"/>
            <Image x:Name="BannerImage" Stretch="UniformToFill"/>
            <Rectangle>
                <Rectangle.Fill>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="#1807111F" Offset="0"/>
                        <GradientStop Color="#E607111F" Offset="1"/>
                    </LinearGradientBrush>
                </Rectangle.Fill>
            </Rectangle>
            <StackPanel Margin="30,0,30,18" VerticalAlignment="Bottom">
                <TextBlock Text="RUNTIME DATA SYSTEM SETUP" FontSize="11" FontWeight="Bold"
                           Foreground="#58D8FF"/>
                <TextBlock Text="Prepare Windows" FontSize="30" FontWeight="SemiBold"
                           Foreground="White" Margin="0,2,0,0"/>
                <TextBlock Text="System tuning, essential applications, and virtual-machine integration"
                           FontSize="12" Foreground="#C7DDF4" Margin="0,2,0,0"/>
            </StackPanel>
        </Grid>

        <Grid Grid.Row="1" Margin="24,14,24,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="340"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="#0D1C2D" CornerRadius="10" Padding="16,14">
                <StackPanel>
                    <TextBlock Text="Setup options" FontSize="18" FontWeight="SemiBold"/>
                    <TextBlock Text="Choose how this Windows image should be prepared."
                               Foreground="#8FA8C2" TextWrapping="Wrap" FontSize="11" Margin="0,3,0,10"/>
                    <TextBlock Text="Configuration preset" Foreground="#B9CDE1" FontSize="11" Margin="0,0,0,4"/>
                    <ComboBox x:Name="PresetChoice" SelectedIndex="0">
                        <ComboBoxItem Content="Aggressive"/>
                        <ComboBoxItem Content="Minimal"/>
                    </ComboBox>
                    <TextBlock x:Name="PresetDescription" TextWrapping="Wrap" Foreground="#7F9AB5"
                               FontSize="10" Margin="0,5,0,8"/>
                    <CheckBox x:Name="InstallSoftwareChoice" Content="Install standard RunTime Data software" IsChecked="True"/>
                    <CheckBox x:Name="GuestToolsChoice"
                              Content="Install virtual-machine guest tools"
                              ToolTip="Selected automatically when supported virtual-machine hardware is detected."/>
                    <CheckBox x:Name="ActivateChoice"
                              Content="Activate Windows and Office"
                              ToolTip="Runs KMS.cmd to activate Windows and Office."/>
                    <CheckBox x:Name="DodSecureChoice"
                              Content="Apply DOD Secure Defaults"
                              ToolTip="Applies DOD/STIG-oriented hardening. This can disable Windows services, protocols, remote access, and application features."/>
                    <CheckBox x:Name="SysprepChoice"
                              Content="Reseal for cloning (Sysprep/OOBE)"
                              ToolTip="Generalizes the installation and shuts down. The next boot asks for a user name and password."/>
                    <CheckBox x:Name="RestartChoice" Content="Restart automatically when finished"/>
                    <Border Background="#102A42" CornerRadius="6" Padding="8" Margin="0,8,0,0">
                        <TextBlock Text="You can minimize this window while setup continues. Detailed logs are written to C:\RTD\log."
                                   Foreground="#9DB8D2" TextWrapping="Wrap" FontSize="10"/>
                    </Border>
                </StackPanel>
            </Border>

            <Border Grid.Column="2" Background="#0D1C2D" CornerRadius="10" Padding="16,14">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Text="Configuration progress" FontSize="18" FontWeight="SemiBold"/>
                    <TextBlock x:Name="CurrentStatus" Grid.Row="1" Text="Ready to configure this system."
                               Foreground="#8FA8C2" FontSize="11" Margin="0,3,0,9"/>
                    <StackPanel Grid.Row="2">
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="InitializeDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="InitializeText" Grid.Column="1" Text="Preparing the environment" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="TuningDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="TuningText" Grid.Column="1" Text="Applying Windows configuration" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="SoftwareDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="SoftwareText" Grid.Column="1" Text="Installing applications and guest tools" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="CompleteDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="CompleteText" Grid.Column="1" Text="Finalizing setup" Foreground="#9CB1C7"/>
                        </Grid>
                        <ProgressBar x:Name="SetupProgress" Height="8" Minimum="0" Maximum="100" Value="0"
                                     Foreground="#20C8F6" Background="#22364A" BorderThickness="0"/>
                    </StackPanel>
                    <Border Grid.Row="3" Background="#07131F" CornerRadius="6" Padding="9" Margin="0,10,0,0">
                        <TextBox x:Name="ActivityOutput" Background="Transparent" BorderThickness="0"
                                 Foreground="#AFC5DB" FontFamily="Consolas" FontSize="11"
                                 IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </Border>
                </Grid>
            </Border>
        </Grid>

        <Grid Grid.Row="2" Margin="24,0,24,10">
            <TextBlock x:Name="FooterStatus" Text="Administrative access ready"
                       VerticalAlignment="Center" Foreground="#6F8CA8" FontSize="12"/>
            <Button x:Name="StartButton" Content="Start setup" HorizontalAlignment="Right"
                    VerticalAlignment="Center" Background="#24C9F4" Foreground="#04111D" MinWidth="145"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controlNames = @(
    "BannerImage", "PresetChoice", "PresetDescription", "InstallSoftwareChoice", "GuestToolsChoice", "ActivateChoice",
    "DodSecureChoice", "SysprepChoice", "RestartChoice",
    "CurrentStatus", "InitializeDot", "InitializeText", "TuningDot", "TuningText",
    "SoftwareDot", "SoftwareText", "CompleteDot", "CompleteText", "SetupProgress",
    "ActivityOutput", "FooterStatus", "StartButton"
)
foreach ($controlName in $controlNames) {
    Set-Variable -Name $controlName -Value $window.FindName($controlName) -Scope Script
}

if ($Script:ResolvedBanner) {
    try {
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.UriSource = New-Object System.Uri -ArgumentList $Script:ResolvedBanner
        $bitmap.EndInit()
        $Script:BannerImage.Source = $bitmap
    } catch {
        # The gradient fallback remains visible when the image cannot be decoded.
    }
}

if ($Preset -eq "Minimal") {
    $Script:PresetChoice.SelectedIndex = 1
}
$Script:InstallSoftwareChoice.IsChecked = -not $SkipSoftware
$Script:GuestToolsChoice.IsChecked = (Test-SetupVirtualMachine) -and -not $SkipGuestTools
$Script:DodSecureChoice.IsChecked = [bool]$ApplyDodSecureDefaults
$Script:RestartChoice.IsChecked = [bool]$Restart

function Update-PresetDescription {
    $selectedPreset = $Script:PresetChoice.SelectedItem.Content
    if ($selectedPreset -eq "Minimal") {
        $Script:PresetDescription.Text = "Keeps bundled applications while reducing telemetry, advertising, and background activity."
    } else {
        $Script:PresetDescription.Text = "Removes consumer applications and applies performance-focused VM and VDI defaults."
    }
}

function Set-SetupStep {
    param(
        [ValidateSet("Initialize", "Tuning", "Software", "Complete")]
        [string]$Step,

        [ValidateSet("Pending", "Active", "Done", "Warning", "Skipped")]
        [string]$State
    )

    $dot = Get-Variable -Name "${Step}Dot" -ValueOnly -Scope Script
    $text = Get-Variable -Name "${Step}Text" -ValueOnly -Scope Script
    switch ($State) {
        "Active" {
            $dot.Fill = "#24C9F4"
            $text.Foreground = "#EAF3FF"
            $text.FontWeight = "SemiBold"
        }
        "Done" {
            $dot.Fill = "#36D399"
            $text.Foreground = "#BDEFD9"
            $text.FontWeight = "Normal"
        }
        "Warning" {
            $dot.Fill = "#F6B94A"
            $text.Foreground = "#F8D99A"
            $text.FontWeight = "Normal"
            $Script:CompletedWithWarnings = $true
        }
        "Skipped" {
            $dot.Fill = "#60758B"
            $text.Foreground = "#71869B"
            $text.FontWeight = "Normal"
        }
        default {
            $dot.Fill = "#3A5068"
            $text.Foreground = "#9CB1C7"
            $text.FontWeight = "Normal"
        }
    }
}

function Add-SetupOutput {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return
    }
    $Script:ActivityOutput.AppendText($Line + [Environment]::NewLine)
    $Script:ActivityOutput.ScrollToEnd()
    try {
        New-Item -Path (Split-Path -Parent $Script:FrontendLog) -ItemType Directory -Force | Out-Null
        Add-Content -LiteralPath $Script:FrontendLog -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $Line) -Encoding UTF8
    } catch {
        # UI output remains available if persistent logging is temporarily unavailable.
    }
}

function Invoke-ConfiguredLicenseActivation {
    $Script:CurrentStatus.Text = "Activating Windows and Office..."
    $Script:FooterStatus.Text = "Running KMS.cmd"
    Add-SetupOutput "Activating Windows and Office..."

    try {
        $output = & $env:ComSpec /d /c 'call "%CORE_DIR%\KMS.cmd" /K-WindowsOffice' 2>&1
        foreach ($line in @($output)) {
            Add-SetupOutput ([string]$line)
        }
        if ($LASTEXITCODE -eq 0) {
            return $true
        }

        Add-SetupOutput "Windows and Office activation failed with exit code $LASTEXITCODE."
        $Script:CompletedWithWarnings = $true
        return $false
    } catch {
        Add-SetupOutput "Windows and Office activation failed: $($_.Exception.Message)"
        $Script:CompletedWithWarnings = $true
        return $false
    }
}

function Invoke-SetupSysprep {
    $sysprep = Join-Path $env:SystemRoot "System32\Sysprep\Sysprep.exe"
    if (-not (Test-Path -LiteralPath $sysprep -PathType Leaf)) {
        Add-SetupOutput "Sysprep was not found at '$sysprep'. The system was not resealed."
        $Script:CompletedWithWarnings = $true
        return $false
    }

    $Script:SysprepInProgress = $true
    $Script:CurrentStatus.Text = "Generalizing Windows and preparing the out-of-box experience..."
    $Script:FooterStatus.Text = "The system will shut down when Sysprep completes"
    Add-SetupOutput "Starting Sysprep with /generalize /oobe /shutdown /quiet."
    try {
        $process = Start-Process -FilePath $sysprep -ArgumentList @("/generalize", "/oobe", "/shutdown", "/quiet") -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Sysprep exited with code $($process.ExitCode)."
        }
        # Sysprep /shutdown cannot finish closing the interactive session while
        # this frontend still reports that resealing is in progress and rejects
        # its own close event.
        $Script:SysprepInProgress = $false
        Add-SetupOutput "Sysprep completed. Closing the setup frontend so Windows can shut down."
        return $true
    } catch {
        $Script:SysprepInProgress = $false
        $Script:CompletedWithWarnings = $true
        Add-SetupOutput "Sysprep failed: $($_.Exception.Message)"
        Add-SetupOutput "Review C:\Windows\System32\Sysprep\Panther\setuperr.log and setupact.log, resolve the reported package or servicing issue, and run Sysprep again."
        return $false
    }
}

function Read-SetupMarker {
    param([string]$Line)

    if ($Line -notmatch '^RTD_STEP:([^:]+):([^:]+)$') {
        return $false
    }

    $step = $Matches[1]
    $state = $Matches[2]
    switch ("$step`:$state") {
        "initialize:start" {
            Set-SetupStep "Initialize" "Active"
            $Script:CurrentStatus.Text = "Preparing folders, logs, and system checks..."
            $Script:SetupProgress.Value = 8
        }
        "initialize:done" {
            Set-SetupStep "Initialize" "Done"
            $Script:SetupProgress.Value = 20
        }
        "tuning:start" {
            Set-SetupStep "Tuning" "Active"
            $Script:CurrentStatus.Text = "Applying Windows configuration..."
            $Script:SetupProgress.Value = 32
        }
        "tuning:done" {
            Set-SetupStep "Tuning" "Done"
            $Script:SetupProgress.Value = 58
        }
        "software:start" {
            Set-SetupStep "Software" "Active"
            $Script:CurrentStatus.Text = "Installing standard applications and integration tools..."
            $Script:SetupProgress.Value = 66
        }
        "software:done" {
            Set-SetupStep "Software" "Done"
            $Script:SetupProgress.Value = 88
        }
        "software:warning" {
            Set-SetupStep "Software" "Warning"
            $Script:SetupProgress.Value = 88
        }
        "software:skipped" {
            Set-SetupStep "Software" "Skipped"
            $Script:SoftwareText.Text = "Application installation skipped"
            $Script:SetupProgress.Value = 88
        }
        "complete:start" {
            Set-SetupStep "Complete" "Active"
            $Script:CurrentStatus.Text = "Finalizing configuration and logs..."
            $Script:SetupProgress.Value = 94
        }
        "complete:warning" {
            Set-SetupStep "Complete" "Warning"
        }
        "complete:restart-required" {
            Set-SetupStep "Complete" "Done"
            $Script:CurrentStatus.Text = "Configuration complete. Restart Windows before final testing."
            $Script:FooterStatus.Text = "Restart recommended"
            $Script:SetupProgress.Value = 100
        }
        "complete:restart" {
            Set-SetupStep "Complete" "Done"
            $Script:CurrentStatus.Text = "Configuration complete. Windows is restarting..."
            $Script:SetupProgress.Value = 100
        }
        "complete:done" {
            Set-SetupStep "Complete" "Done"
            $Script:SetupProgress.Value = 100
        }
    }
    return $true
}

function Receive-SetupOutput {
    param([int]$MaximumLines = 80)

    $line = $null
    $linesRead = 0
    while ($linesRead -lt $MaximumLines -and $Script:LineQueue.TryDequeue([ref]$line)) {
        if (-not (Read-SetupMarker $line)) {
            Add-SetupOutput $line
        }
        $line = $null
        $linesRead++
    }
}

function Complete-SetupFrontend {
    param([int]$ExitCode)

    $Script:WorkerRunning = $false
    $Script:StartButton.IsEnabled = $true
    $Script:StartButton.Content = "Close"
    $Script:PresetChoice.IsEnabled = $false
    $Script:InstallSoftwareChoice.IsEnabled = $false
    $Script:GuestToolsChoice.IsEnabled = $false
    $Script:ActivateChoice.IsEnabled = $false
    $Script:DodSecureChoice.IsEnabled = $false
    $Script:SysprepChoice.IsEnabled = $false
    $Script:RestartChoice.IsEnabled = $false

    if ($ExitCode -ne 0) {
        Set-SetupStep "Complete" "Warning"
        $Script:CurrentStatus.Text = "Setup stopped with an error. Review the activity output and logs."
        $Script:FooterStatus.Text = "Worker exit code: $ExitCode"
        $Script:StartButton.Background = "#F6B94A"
        Add-SetupOutput "Configuration process exited with code $ExitCode."
    } else {
        if ($Script:ActivateChoice.IsChecked) {
            Invoke-ConfiguredLicenseActivation | Out-Null
        }

        if ($Script:SysprepChoice.IsChecked) {
            if (Invoke-SetupSysprep) {
                Set-SetupStep "Complete" "Done"
                $Script:SetupProgress.Value = 100
                $Script:CurrentStatus.Text = "System resealed successfully. Waiting for Windows to shut down."
                $Script:FooterStatus.Text = "Ready to capture or clone after shutdown"
                $Script:StartButton.IsEnabled = $true
                $Script:StartButton.Content = "Close"
                $window.Close()
                return
            }
        }
    }

    if ($ExitCode -eq 0 -and $Script:CompletedWithWarnings) {
        $Script:SetupProgress.Value = 100
        $Script:CurrentStatus.Text = "Setup completed with warnings. Review the log for unresolved items."
        $Script:FooterStatus.Text = "Completed with warnings"
        $Script:StartButton.Background = "#F6B94A"
    } elseif ($ExitCode -eq 0) {
        Set-SetupStep "Complete" "Done"
        $Script:SetupProgress.Value = 100
        $Script:CurrentStatus.Text = "Windows setup completed successfully."
        $Script:FooterStatus.Text = "Setup complete"
        $Script:StartButton.Background = "#36D399"
    }

    if ($ExitCode -eq 0 -and $Script:RestartChoice.IsChecked -and $Script:ActivateChoice.IsChecked -and -not $Script:SysprepChoice.IsChecked) {
        try {
            Add-SetupOutput "Activation attempt complete. Windows will restart in 5 seconds."
            $Script:CurrentStatus.Text = "Setup complete. Windows is restarting..."
            $Script:FooterStatus.Text = "Restart scheduled"
            Start-Process -FilePath (Join-Path $env:SystemRoot "System32\shutdown.exe") -ArgumentList @("/r", "/t", "5", "/d", "p:2:4") | Out-Null
        } catch {
            $Script:CompletedWithWarnings = $true
            Add-SetupOutput "Windows could not be restarted automatically: $($_.Exception.Message)"
            $Script:FooterStatus.Text = "Restart Windows manually"
        }
    }
}

function Start-SetupWorker {
    if ($Script:WorkerRunning) {
        return
    }

    if ($Script:AutoStartTimer) {
        $Script:AutoStartTimer.Stop()
        $Script:AutoStartTimer = $null
    }

    $selectedPreset = [string]$Script:PresetChoice.SelectedItem.Content
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $Script:ResolvedWorker),
        "-Preset", $selectedPreset
    )
    if (-not $Script:InstallSoftwareChoice.IsChecked) {
        $arguments += "-SkipSoftware"
    }
    if (-not $Script:GuestToolsChoice.IsChecked) {
        $arguments += "-SkipGuestTools"
    }
    if ($Script:DodSecureChoice.IsChecked) {
        $arguments += "-ApplyDodSecureDefaults"
    }
    if ($Script:RestartChoice.IsChecked -and -not $Script:ActivateChoice.IsChecked -and -not $Script:SysprepChoice.IsChecked) {
        $arguments += "-Restart"
    }

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = Join-Path $PSHOME "powershell.exe"
    $processInfo.Arguments = $arguments -join " "
    $processInfo.WorkingDirectory = Split-Path -Parent $Script:ResolvedWorker
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true

    $Script:WorkerProcess = New-Object System.Diagnostics.Process
    $Script:WorkerProcess.StartInfo = $processInfo
    [SetupOutputBridge]::Attach($Script:WorkerProcess, $Script:LineQueue)

    try {
        if (-not $Script:WorkerProcess.Start()) {
            throw "The configuration process did not start."
        }
        $Script:WorkerProcess.BeginOutputReadLine()
        $Script:WorkerProcess.BeginErrorReadLine()
        $Script:WorkerRunning = $true
        $Script:CompletedWithWarnings = $false
        $Script:PresetChoice.IsEnabled = $false
        $Script:InstallSoftwareChoice.IsEnabled = $false
        $Script:GuestToolsChoice.IsEnabled = $false
        $Script:ActivateChoice.IsEnabled = $false
        $Script:DodSecureChoice.IsEnabled = $false
        $Script:SysprepChoice.IsEnabled = $false
        $Script:RestartChoice.IsEnabled = $false
        $Script:StartButton.IsEnabled = $false
        $Script:StartButton.Content = "Setup running"
        $Script:FooterStatus.Text = "Do not turn off this computer"
        $Script:ActivityOutput.Clear()
        Add-SetupOutput "Starting $selectedPreset Windows configuration..."
    } catch {
        $Script:CurrentStatus.Text = "The configuration process could not be started."
        $Script:FooterStatus.Text = $_.Exception.Message
        $Script:StartButton.IsEnabled = $true
        $Script:StartButton.Content = "Try again"
        Set-SetupStep "Initialize" "Warning"
    }
}

$Script:PresetChoice.Add_SelectionChanged({ Update-PresetDescription })
$Script:SysprepChoice.Add_Checked({
    $Script:RestartChoice.IsChecked = $false
    $Script:RestartChoice.IsEnabled = $false
    $Script:ActivateChoice.IsChecked = $false
    $Script:ActivateChoice.IsEnabled = $false
})
$Script:SysprepChoice.Add_Unchecked({
    if (-not $Script:WorkerRunning) {
        $Script:RestartChoice.IsEnabled = $true
        $Script:ActivateChoice.IsEnabled = $true
    }
})
$Script:StartButton.Add_Click({
    if ($Script:StartButton.Content -eq "Close") {
        $window.Close()
    } else {
        if ($Script:DodSecureChoice.IsChecked) {
            $confirmation = [System.Windows.MessageBox]::Show(
                "DOD secure defaults apply extensive STIG-oriented hardening. They may disable services, legacy protocols, remote access, or application features and can require additional site-specific configuration.`n`nContinue with DOD secure defaults?",
                "Confirm DOD security hardening",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }
        }
        if ($Script:SysprepChoice.IsChecked) {
            $confirmation = [System.Windows.MessageBox]::Show(
                "After setup, Sysprep will generalize this installation and shut down the computer.`n`nThe next boot will start the Windows out-of-box experience and request a new user account. Activation must be performed on the deployed clone after OOBE. Continue?",
                "Confirm system reseal",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }
        }
        Start-SetupWorker
    }
})

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(120)
$timer.Add_Tick({
    Receive-SetupOutput

    if ($Script:WorkerRunning -and $Script:WorkerProcess.HasExited) {
        $Script:WorkerProcess.WaitForExit()
        Receive-SetupOutput -MaximumLines 10000
        Complete-SetupFrontend $Script:WorkerProcess.ExitCode
    }
})
$timer.Start()

$window.Add_Closing({
    param($sender, $eventArgs)
    if ($Script:WorkerRunning -or $Script:SysprepInProgress) {
        [System.Windows.MessageBox]::Show(
            "Windows configuration or system resealing is still running. Minimize this window and allow the current operation to finish.",
            "RunTime Data setup is still running",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        ) | Out-Null
        $eventArgs.Cancel = $true
    }
})

Update-PresetDescription
if ($AutoStart) {
    $window.Add_ContentRendered({
        if ($Script:AutoStartTimer) {
            return
        }

        $Script:FooterStatus.Text = "Setup starts automatically in 05:00"
        $Script:AutoStartTimer = New-Object System.Windows.Threading.DispatcherTimer
        $Script:AutoStartTimer.Interval = [TimeSpan]::FromSeconds(1)
        $Script:AutoStartTimer.Add_Tick({
            if ($Script:WorkerRunning) {
                $Script:AutoStartTimer.Stop()
                $Script:AutoStartTimer = $null
                return
            }

            $Script:AutoStartRemainingSeconds--
            if ($Script:AutoStartRemainingSeconds -le 0) {
                $Script:AutoStartTimer.Stop()
                $Script:AutoStartTimer = $null
                Start-SetupWorker
                return
            }

            $minutes = [Math]::Floor($Script:AutoStartRemainingSeconds / 60)
            $seconds = $Script:AutoStartRemainingSeconds % 60
            $Script:FooterStatus.Text = "Setup starts automatically in {0:00}:{1:00}" -f $minutes, $seconds
        })
        $Script:AutoStartTimer.Start()
    })
}
$window.ShowDialog() | Out-Null
