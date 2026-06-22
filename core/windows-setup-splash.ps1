# RTD Windows Setup graphical launcher
#
# This WPF frontend keeps the configuration worker usable from a terminal while
# providing an elevated, splash-style progress experience for interactive runs.

[CmdletBinding()]
param(
    [ValidateSet("Aggressive", "Minimal")]
    [string]$Preset = "Aggressive",

    [switch]$SkipSoftware,

    [switch]$Restart,

    [switch]$AutoStart,

    [string]$WorkerPath
)

$ErrorActionPreference = "Stop"
$Script:WorkerProcess = $null
$Script:WorkerRunning = $false
$Script:CompletedWithWarnings = $false
$Script:LineQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$Script:WorkerUrl = "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/rtd-oem-win11-config.ps1"
$Script:BannerUrl = "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/Media_files/rtd-bootstrap-gui-banner.png"

function Test-SetupAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
    if ($Restart) {
        $arguments += "-Restart"
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
            "RTD Windows Setup",
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

function Resolve-SetupWorker {
    $candidates = @()
    if ($WorkerPath) {
        $candidates += $WorkerPath
    }
    $candidates += @(
        (Join-Path $PSScriptRoot "rtd-oem-win11-config.ps1"),
        "C:\RTD\core\rtd-oem-win11-config.ps1",
        "C:\RTD\cache\rtd-oem-win11-config.ps1"
    )

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $cacheDirectory = "C:\RTD\cache"
    $downloadPath = Join-Path $cacheDirectory "rtd-oem-win11-config.ps1"
    New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null
    Invoke-WebRequest -Uri $Script:WorkerUrl -OutFile $downloadPath -UseBasicParsing
    return $downloadPath
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
        "RTD Windows Setup",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}
$Script:ResolvedBanner = Resolve-SetupBanner

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RTD Windows Setup" Width="1040" Height="760"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
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
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,7,0,7"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="10,7"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="224"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="82"/>
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
            <StackPanel Margin="42,0,42,27" VerticalAlignment="Bottom">
                <TextBlock Text="RTD SYSTEM SETUP" FontSize="13" FontWeight="Bold"
                           Foreground="#58D8FF"/>
                <TextBlock Text="Prepare Windows 11" FontSize="36" FontWeight="SemiBold"
                           Foreground="White" Margin="0,5,0,0"/>
                <TextBlock Text="System tuning, essential applications, and virtual-machine integration"
                           FontSize="14" Foreground="#C7DDF4" Margin="0,5,0,0"/>
            </StackPanel>
        </Grid>

        <Grid Grid.Row="1" Margin="34,25,34,18">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="300"/>
                <ColumnDefinition Width="22"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="#0D1C2D" CornerRadius="12" Padding="22">
                <StackPanel>
                    <TextBlock Text="Setup options" FontSize="20" FontWeight="SemiBold"/>
                    <TextBlock Text="Choose how this Windows image should be prepared."
                               Foreground="#8FA8C2" TextWrapping="Wrap" Margin="0,5,0,20"/>
                    <TextBlock Text="Configuration preset" Foreground="#B9CDE1" Margin="0,0,0,7"/>
                    <ComboBox x:Name="PresetChoice" SelectedIndex="0">
                        <ComboBoxItem Content="Aggressive"/>
                        <ComboBoxItem Content="Minimal"/>
                    </ComboBox>
                    <TextBlock x:Name="PresetDescription" TextWrapping="Wrap" Foreground="#7F9AB5"
                               FontSize="12" Margin="0,9,0,16"/>
                    <CheckBox x:Name="InstallSoftwareChoice" Content="Install standard RTD software" IsChecked="True"/>
                    <CheckBox x:Name="RestartChoice" Content="Restart automatically when finished"/>
                    <Border Background="#102A42" CornerRadius="7" Padding="12" Margin="0,18,0,0">
                        <TextBlock Text="You can minimize this window while setup continues. Detailed logs are written to C:\RTD\log."
                                   Foreground="#9DB8D2" TextWrapping="Wrap" FontSize="12"/>
                    </Border>
                </StackPanel>
            </Border>

            <Border Grid.Column="2" Background="#0D1C2D" CornerRadius="12" Padding="22">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Text="Configuration progress" FontSize="20" FontWeight="SemiBold"/>
                    <TextBlock x:Name="CurrentStatus" Grid.Row="1" Text="Ready to configure this system."
                               Foreground="#8FA8C2" Margin="0,5,0,16"/>
                    <StackPanel Grid.Row="2">
                        <Grid Margin="0,0,0,13">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="InitializeDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="InitializeText" Grid.Column="1" Text="Preparing the environment" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,13">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="TuningDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="TuningText" Grid.Column="1" Text="Applying Windows configuration" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,13">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="SoftwareDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="SoftwareText" Grid.Column="1" Text="Installing applications and guest tools" Foreground="#9CB1C7"/>
                        </Grid>
                        <Grid Margin="0,0,0,18">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Ellipse x:Name="CompleteDot" Width="13" Height="13" Fill="#3A5068"/>
                            <TextBlock x:Name="CompleteText" Grid.Column="1" Text="Finalizing setup" Foreground="#9CB1C7"/>
                        </Grid>
                        <ProgressBar x:Name="SetupProgress" Height="8" Minimum="0" Maximum="100" Value="0"
                                     Foreground="#20C8F6" Background="#22364A" BorderThickness="0"/>
                    </StackPanel>
                    <Border Grid.Row="3" Background="#07131F" CornerRadius="7" Padding="12" Margin="0,18,0,0">
                        <TextBox x:Name="ActivityOutput" Background="Transparent" BorderThickness="0"
                                 Foreground="#AFC5DB" FontFamily="Consolas" FontSize="11"
                                 IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </Border>
                </Grid>
            </Border>
        </Grid>

        <Grid Grid.Row="2" Margin="34,0,34,18">
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
    "BannerImage", "PresetChoice", "PresetDescription", "InstallSoftwareChoice", "RestartChoice",
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
    $Script:RestartChoice.IsEnabled = $false

    if ($ExitCode -ne 0) {
        Set-SetupStep "Complete" "Warning"
        $Script:CurrentStatus.Text = "Setup stopped with an error. Review the activity output and logs."
        $Script:FooterStatus.Text = "Worker exit code: $ExitCode"
        $Script:StartButton.Background = "#F6B94A"
        Add-SetupOutput "Configuration process exited with code $ExitCode."
    } elseif ($Script:CompletedWithWarnings) {
        $Script:SetupProgress.Value = 100
        $Script:CurrentStatus.Text = "Setup completed with warnings. Review the log for unresolved items."
        $Script:FooterStatus.Text = "Completed with warnings"
        $Script:StartButton.Background = "#F6B94A"
    } else {
        Set-SetupStep "Complete" "Done"
        $Script:SetupProgress.Value = 100
        $Script:CurrentStatus.Text = "Windows setup completed successfully."
        $Script:FooterStatus.Text = "Setup complete"
        $Script:StartButton.Background = "#36D399"
    }
}

function Start-SetupWorker {
    if ($Script:WorkerRunning) {
        return
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
    if ($Script:RestartChoice.IsChecked) {
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
$Script:StartButton.Add_Click({
    if ($Script:StartButton.Content -eq "Close") {
        $window.Close()
    } else {
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
    if ($Script:WorkerRunning) {
        [System.Windows.MessageBox]::Show(
            "Windows configuration is still running. Minimize this window and allow the current operation to finish.",
            "Setup is still running",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        ) | Out-Null
        $eventArgs.Cancel = $true
    }
})

Update-PresetDescription
if ($AutoStart) {
    $window.Add_ContentRendered({ Start-SetupWorker })
}
$window.ShowDialog() | Out-Null
