# ------------------------------------------------------------
# Create workstation prep working directory and navigate to it
# ------------------------------------------------------------
$prepDir = "C:\prep"
if (-not (Test-Path $prepDir)) {
    New-Item -Path $prepDir -ItemType Directory
}
Set-Location -Path $prepDir
# Set Execution Policy
# ------------------------------------------------------------
# Temporarily set script execution policy - this will be reversed once the program finishes
# This prevents us from having to send the set execution bypass command every time we run a script
# ------------------------------------------------------------
Set-ExecutionPolicy Bypass -Scope LocalMachine -Force
#-------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
# Required for later versions of Windows 11, as it does not load automatically and causes errors
# ------------------------------------------------------------
# Function to Prompt User with Two-Button Choice Dialog plus Help Button
function Get-Choice {
    param (
        [string]$Prompt,
        [string]$DialogTitle,
        [string]$HelpText
    )
    $form = New-Object Windows.Forms.Form
    $form.Text = $DialogTitle
    $form.Size = New-Object Drawing.Size(400, 200) # Increased the height of the form

    $label = New-Object Windows.Forms.Label
    $label.Text = $Prompt
    $label.Size = New-Object Drawing.Size(350, 60) # Increased the height of the label
    $label.Location = New-Object Drawing.Point(25, 20)
    $form.Controls.Add($label)

    $buttonYes = New-Object Windows.Forms.Button
    $buttonYes.Text = "Yes"
    $buttonYes.DialogResult = [Windows.Forms.DialogResult]::Yes
    $buttonYes.Location = New-Object Drawing.Point(50, 120) # Adjusted button position
    $form.Controls.Add($buttonYes)

    $buttonNo = New-Object Windows.Forms.Button
    $buttonNo.Text = "No"
    $buttonNo.DialogResult = [Windows.Forms.DialogResult]::No
    $buttonNo.Location = New-Object Drawing.Point(150, 120) # Adjusted button position
    $form.Controls.Add($buttonNo)

    $helpButton = New-Object Windows.Forms.Button
    $helpButton.Text = "Help"
    $helpButton.Location = New-Object Drawing.Point(250, 120) # Adjusted button position
    $form.Controls.Add($helpButton)

    $form.ControlBox = $false
    $form.TopMost = $true
    $form.Add_Shown({$form.Activate()})

    $helpForm = $null

    $helpButton.Add_Click({
        $helpForm = New-Object Windows.Forms.Form
        $helpForm.Text = "Help"
        $helpForm.Size = New-Object Drawing.Size(400, 275) # Increased the height of the form
        $helpForm.TopMost = $true

        $helpLabel = New-Object Windows.Forms.Label
        $helpLabel.Text = $HelpText
        $helpLabel.Size = New-Object Drawing.Size(350, 160) # Increased the height of the label
        $helpLabel.Location = New-Object Drawing.Point(25, 20)
        $helpLabel.AutoSize = $false # Allow text to wrap
        $helpLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft # Align text to the top-left
        $helpForm.Controls.Add($helpLabel)

        $helpCloseButton = New-Object Windows.Forms.Button
        $helpCloseButton.Text = "Close"
        $helpCloseButton.Location = New-Object Drawing.Point(150, 200) # Adjusted button position
        $helpForm.Controls.Add($helpCloseButton)

        $helpCloseButton.Add_Click({
            $helpForm.Close()
        })

        $helpForm.ShowDialog()
    })

    $result = $form.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::Yes) {
        return "Yes"
    } else {
        return "No"
    }
}

# Function to Prompt User for SplashtopSOS Download

function Prompt-DownloadSplashtopSOS {
# This section creates the Help dialogue text box
    $helpText = @"
    Clicking Yes will download the latest 
    version of SplashtopSOS to the Default Desktop 
    for new users.

    Note: This will only download the installer
    for new users. It will not install SplashtopSOS
    for the current user. There is another function later
    on that will install SplashtopSOS for the current user.
"@

    $choice = $null
    $choice = Get-Choice -Prompt "Do you want to download Splashtop SOS for all users?" -DialogTitle "Install SplashtopSOS" -HelpText $helpText
    if ($choice -eq "Yes") {
        Download-SplashtopSOS
    } else {
        Write-Host "----------------------------------------------------"   -ForegroundColor White -BackgroundColor Green
        Write-Host "       Skipping SOS Shortcut Install                "   -ForegroundColor White -BackgroundColor Green
        Write-Host "----------------------------------------------------"   -ForegroundColor White -BackgroundColor Green
    }
}

# Function to Download Splashtop SOS for All Users
function Download-SplashtopSOS {
    $sosUri = 'https://download.splashtop.com/sos/SplashtopSOS.exe'
    $sosPath = 'C:\Users\Default\Desktop\SplashtopSOS.exe'
    Invoke-WebRequest -Uri $sosUri -OutFile $sosPath
    Write-Host "----------------------------------------------------"   -ForegroundColor White -BackgroundColor Green
    Write-Host "Splashtop SOS installed for All New Users           "   -ForegroundColor White -BackgroundColor Green
    Write-Host "----------------------------------------------------"   -ForegroundColor White -BackgroundColor Green
}
# Function to Prompt User for Taskbar Tweaks
function Prompt-TaskbarTweaks {
    $helpText = @"
    Clicking Yes will apply the following tweaks to the
    Registry of New Users:
    
1) Removes Widgets from the Taskbar
2) Removes Chat from the Taskbar
3) Default Start Menu alignment Left
4) Removes search from the Taskbar

Note: this will only apply the tweaks to new users
not the current user.
"@

    $choice = $null
    $choice = Get-Choice -Prompt "Do you want to apply taskbar tweaks to new users?" -DialogTitle "Taskbar Tweaks" -HelpText $helpText
    if ($choice -eq "Yes") {
        Apply-TaskbarTweaks
    } else {
        Write-Host "Skipping taskbar tweaks for new users."
    }
}

# Function to Apply Taskbar Tweaks to Default User
function Apply-TaskbarTweaks {
    # Load the Default User Registry hive
    REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT

    # Disable error messages for this specific operation
    $ErrorActionPreference = 'SilentlyContinue'

    # Attempt to create the registry keys without showing errors if they already exist
    New-itemproperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword
    New-itemproperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword
    New-itemproperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword

    # Reset the error action preference to its previous value
    $ErrorActionPreference = 'Continue'

    # Unload the Default User Registry hive
    REG UNLOAD HKLM\Default

    Write-Host "----------------------------------------------------" -ForegroundColor White -BackgroundColor Green
    Write-Host "      Taskbar Tweaks Applied for All New Users      " -ForegroundColor White -BackgroundColor Green
    Write-Host "----------------------------------------------------" -ForegroundColor White -BackgroundColor Green
}
# Call the prompt functions
Prompt-DownloadSplashtopSOS
Prompt-TaskbarTweaks

# ----------------------------- Test for Choco and BoxStarter -------------------
Write-Host "------------------------------------------" -ForegroundColor Black -BackgroundColor White
Write-Host "    Checking for Choco and BoxStarter     " -ForegroundColor Black -BackgroundColor White
Write-Host "------------------------------------------" -ForegroundColor Black -BackgroundColor White

# ------------------------------------------------------------
# Chocolatey / ProGet / WireGuard settings for this branch
# ------------------------------------------------------------
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
$internalChocoSourceName = "internal"
$internalChocoSourceUrl = "http://10.121.116.1:8624/nuget/choco"
$wireGuardConfigPath = "C:\prep\wg\tech.conf"
$wireGuardExePath = "C:\Program Files\WireGuard\wireguard.exe"
$proGetHost = "10.121.116.1"
$proGetPort = 8624

# ------------------------------------------------------------
# Install Chocolatey if not already installed
# ------------------------------------------------------------
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
$chocoInstalled = Test-Path $chocoPath

if (-not $chocoInstalled) {
    Write-Host "Chocolatey not found. Installing Chocolatey using winget..." -ForegroundColor Cyan

    winget install --id Chocolatey.Chocolatey -e --silent --accept-package-agreements --accept-source-agreements

    Start-Sleep -Seconds 5
}
else {
    Write-Host "========================================" -ForegroundColor DarkGreen
    Write-Host "      Chocolatey already installed      " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor DarkGreen
}
# ------------------------------------------------------------
# Path to Chocolatey executable declared again because the
# previous iex sometimes invokes a PowerShell session that does
# not retain prior declarations.
# ------------------------------------------------------------
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"

# Enable global confirmation for Chocolatey
& $chocoPath feature enable -n allowGlobalConfirmation

# ------------------------------------------------------------
# Configure WireGuard and point Chocolatey to the ProGet proxy
# when the WireGuard tunnel and ProGet feed are reachable.
#
# Expected tech workflow:
# 1. Copy tech.conf to C:\prep\wg\tech.conf before running this script.
# 2. Run this branch of workstationprep.ps1.
# 3. Script installs WireGuard with winget, imports the tunnel,
#    verifies ProGet is reachable, then switches Chocolatey sources.
#
# If WireGuard, the config file, or ProGet is unavailable, the script
# leaves the normal Chocolatey community source enabled so installs
# do not get stranded.
# ------------------------------------------------------------
$wingetInstalled = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null

if ($wingetInstalled) {
    Write-Host "Winget detected. Installing WireGuard..." -ForegroundColor Cyan

    winget install --id WireGuard.WireGuard -e --silent --accept-package-agreements --accept-source-agreements

    Start-Sleep -Seconds 5

    if (Test-Path $wireGuardConfigPath) {
        Write-Host "WireGuard config found at $wireGuardConfigPath" -ForegroundColor Cyan

        if (Test-Path $wireGuardExePath) {
            Write-Host "Importing and starting WireGuard tunnel..." -ForegroundColor Cyan
            & $wireGuardExePath /installtunnelservice `"$wireGuardConfigPath`"

            Start-Sleep -Seconds 8
            $proGetReachable = $false
$tcpClient = New-Object System.Net.Sockets.TcpClient

try {
    $connectTask = $tcpClient.BeginConnect($proGetHost, $proGetPort, $null, $null)

    if ($connectTask.AsyncWaitHandle.WaitOne(3000, $false)) {
        try {
            $tcpClient.EndConnect($connectTask)
            $proGetReachable = $true
        }
        catch {
            $proGetReachable = $false
            Write-Warning "Failed to connect to ProGet at ${proGetHost}:$proGetPort. $($_.Exception.Message)"
        }
    }
}
finally {
    $tcpClient.Close()
}

            if ($proGetReachable) {
                Write-Host "ProGet is reachable. Switching Chocolatey to internal ProGet source..." -ForegroundColor Cyan

                # Remove any old copy of the internal source so this is idempotent.
                & $chocoPath source remove -n=$internalChocoSourceName 2>$null

                & $chocoPath source add --name="'$internalChocoSourceName'" --source="'$internalChocoSourceUrl'"
                & $chocoPath source disable -n=chocolatey
            } else {
                Write-Host "ProGet is not reachable over WireGuard. Leaving Chocolatey community source enabled." -ForegroundColor Yellow
            }
        } else {
            Write-Host "WireGuard executable not found after install. Leaving Chocolatey community source enabled." -ForegroundColor Yellow
        }
    } else {
        Write-Host "WireGuard config not found at $wireGuardConfigPath. Leaving Chocolatey community source enabled." -ForegroundColor Yellow
    }
} else {
    Write-Host "Winget not found. Skipping WireGuard and ProGet setup. Leaving Chocolatey community source enabled." -ForegroundColor Yellow
}

# Install Boxstarter using Chocolatey
& $chocoPath install boxstarter --force

# ------------------------------------------------------------
# Current version of this script uses Python 3.10.6 to present a 
# checkbox screen for installing apps from chocolatey
# This will probably be changed to pure Powershell later
# ------------------------------------------------------------
# Check if Python is already installed
# We use the chocolatey default install of Python 3.10.6
# Because not all installations of Windows 11 will have Python
# pre-installed
# This is the default path that Chocolatey installs Python to
# If you changed it, you will need to change it here as well
# ------------------------------------------------------------
$pythonInstalled = Test-Path "C:\python310\python.exe"

# ------------------------------------------------------------
# This version of the script clones the repository using git
# You may uninstall git later using the uninstall function of 
# the python installer app. Note: if you run this script again
# git will be reinstalled
# ------------------------------------------------------------
# Check if Git is already installed
$gitInstalled = (Get-Command git -ErrorAction SilentlyContinue) -ne $null

# Install Python using Chocolatey if not already installed
if (-not $pythonInstalled) {
    & $chocoPath install python310 --force
}

# Install Git using Chocolatey if not already installed
if (-not $gitInstalled) {
    & C:\ProgramData\chocolatey\choco install git --force
# ------------------------------------------------------------
# The default installation of git installs context menu entries
# We need to remove these because most users will not have a need 
# for them
# ------------------------------------------------------------
    # Define the list of registry paths to remove Git context menu entries
    $registryPathsToRemove = @(
        "HKCU:\Software\Classes\Directory\shell\git_gui",
        "HKCU:\Software\Classes\Directory\shell\git_shell",
        "HKCU:\Software\Classes\LibraryFolder\background\shell\git_gui",
        "HKCU:\Software\Classes\LibraryFolder\background\shell\git_shell",
        "HKLM:\SOFTWARE\Classes\Directory\background\shell\git_gui",
        "HKLM:\SOFTWARE\Classes\Directory\background\shell\git_shell"
    )

    # Loop through the list of registry paths and remove them
    foreach ($path in $registryPathsToRemove) {
        # Remove the registry key and its children
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }

    Write-Host "----------------------------------------------------" -ForegroundColor White -BackgroundColor Green
    Write-Host "Git context menu entries removed from the registry  " -ForegroundColor White -BackgroundColor Green
    Write-Host "----------------------------------------------------" -ForegroundColor White -BackgroundColor Green
}
# ------------------------------------------------------------
# Check if the machine is running as a VMware virtual machine
# ------------------------------------------------------------
$vmwareVm = Get-WmiObject -Namespace "root\cimv2" -Class Win32_ComputerSystem | Where-Object { $_.Manufacturer -eq "VMware, Inc." }

if ($vmwareVm) {
    Write-Host "-------------------------------------------------------------"  -ForegroundColor White -BackgroundColor Green
    Write-Host "Detected VMware virtual machine. Installing VMware Tools..."    -ForegroundColor White -BackgroundColor Green
    Write-Host "-------------------------------------------------------------"  -ForegroundColor White -BackgroundColor Green
    & $chocoPath install vmware-tools --force
} else {
    Write-Host "-----------------------------------------------------------------------------" -ForegroundColor White -BackgroundColor Green
    Write-Host "Not running as a VMware virtual machine. Skipping VMware Tools installation. " -ForegroundColor White -BackgroundColor Green
    Write-Host "-----------------------------------------------------------------------------" -ForegroundColor White -BackgroundColor Green
}

# ------------------------------------------------------------
# Check if the machine is running as a QEMU virtual machine
# ------------------------------------------------------------
$qemuVm = Get-WmiObject -Namespace "root\cimv2" -Class Win32_ComputerSystem | Where-Object {
    $_.Manufacturer -match "QEMU" -or $_.Model -match "Standard PC (i440FX + PIIX, 1996)" -or $_.Model -match "Q35"
}
if ($qemuVm) {
    Write-Host "-------------------------------------------------------------"  -ForegroundColor White -BackgroundColor Blue
    Write-Host "Detected QEMU virtual machine. Installing QEMU Guest Agent..." -ForegroundColor White -BackgroundColor Blue
    Write-Host "-------------------------------------------------------------"  -ForegroundColor White -BackgroundColor Blue
    & $chocoPath install qemu-guest-agent -y --force --ignore-package-exit-codes
    Write-Host "-------------------------------------------------------------------"  -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "Reminder: A system reboot is required to complete the installation." -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "Please plan to reboot your system after the script completes.      " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "-------------------------------------------------------------------"  -ForegroundColor Black -BackgroundColor Yellow
} else {
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor White -BackgroundColor Blue
    Write-Host "Not running as a QEMU virtual machine. Skipping QEMU Guest Agent installation." -ForegroundColor White -BackgroundColor Blue
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor White -BackgroundColor Blue
}

# ------------------------------------------------------------
# Set Path to git.exe
# ------------------------------------------------------------
$gitPath = "C:\Program Files\Git\bin\git.exe"

# ------------------------------------------------------------
# Check if the repository has been cloned, if not, clone it.
# ------------------------------------------------------------
$repoPath = "c:\prep\NewWindowsScripts"
if (-not (Test-Path -Path $repoPath)) {
    # Clone the GitHub repository branch that contains ProGet/WireGuard changes
    $gitRepoUrl = "https://github.com/networkabilityllc/NewWindowsScripts"
    $gitBranch = "proget-proxy-wireguard"
    Start-Process -FilePath $gitPath -ArgumentList "clone", "--branch", $gitBranch, "--single-branch", $gitRepoUrl, $repoPath -Wait
} else {
	# ------------------------------------------------------------
	# If already cloned, do a git pull to refresh it in case we 
    # changed something
    # ------------------------------------------------------------
    # Update the repository
	
    Set-Location -Path $repoPath
    & $gitPath fetch origin proget-proxy-wireguard
    & $gitPath switch proget-proxy-wireguard
    & $gitPath pull
}

# Load the PresentationFramework assembly
# ------------------------------------------------------------
# This was being used for a graphical Powershell window using WPF. 
# It is currently unused, 
# but may be used in lieu of python in the future
# ------------------------------------------------------------
# Add-Type -AssemblyName PresentationFramework

# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'
# ------------------------------------------------------------
# This section is for the Boxstarter commands that will be run
# to configure our default settings and environment
# It modifies the registry and sets the taskbar options
# and removes some Windows 10/11 annoyances
# ------------------------------------------------------------
# Run the commands interactively
# Disable error messages for this specific operation
$ErrorActionPreference = 'SilentlyContinue'
Disable-UAC -Confirm:$false
Disable-BingSearch -ErrorAction SilentlyContinue
Disable-GameBarTips -ErrorAction SilentlyContinue
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
Set-BoxstarterTaskbarOptions -Size Large -Dock Bottom -Combine Always -AlwaysShowIconsOn
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
# ------------------------------------------------------------
# This section restores the default context menu for Windows 11
# ------------------------------------------------------------
# Restore the classic right-click context menu
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
# ------------------------------------------------------------
# This section sets the mouse hover time to a very long time
# It effectively disables the hover text on the taskbar and 
# prevents the thumbnails from popping up
# ------------------------------------------------------------
# Set Mouse Hover Time for Taskbar to a very long time to prevent hover text
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value 10000
# ------------------------------------------------------------
# In some instances, the registry settings above do not take
# So we set them again here
# ------------------------------------------------------------
# Set the registry value to show hidden files and folders for the current user
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
# ------------------------------------------------------------
# Not sure if this works. May remove it later
# ------------------------------------------------------------
# Set the registry value to show hidden files and folders for all users
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "CheckedValue" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "DefaultValue" -Value 1

# Reset the error action preference to its previous value
$ErrorActionPreference = 'Continue'
# ------------------------------------------------------------
# This section creates a shortcut on the desktop for the
# Post User Install script. This script will be run by the
# domain admin after the user logs in for the first time.
# It repeats some of the settings above, because many of
# the above settings are not global and only apply to the
# user that is logged in when they are applied.
# This will also install the post-user install shortcut
# to the current user's desktop
# ------------------------------------------------------------
# Set the paths
$targetPathPostUserInstall = "C:\prep\NewWindowsScripts\post-user-install.bat"
$iconPathPostUserInstall = "C:\prep\NewWindowsScripts\installme.ico"

$targetPathChocoApps = "C:\prep\NewWindowsScripts\chocoapps.bat"
$iconPathChocoApps = "C:\prep\NewWindowsScripts\installer.ico"

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut for the Default user - Post User Install
$shortcutPathDefaultPostUserInstall = "C:\Users\Default\Desktop\Post User Install.lnk"
$ShortcutDefaultPostUserInstall = $WshShell.CreateShortcut($shortcutPathDefaultPostUserInstall)
$ShortcutDefaultPostUserInstall.TargetPath = $targetPathPostUserInstall
$ShortcutDefaultPostUserInstall.IconLocation = $iconPathPostUserInstall
$ShortcutDefaultPostUserInstall.Description = "Shortcut to Post-User-Install Script"
$ShortcutDefaultPostUserInstall.Save()

# Create the shortcut for the current user - Post User Install
$currentUserName = $env:USERNAME
$shortcutPathCurrentUserPostUserInstall = "C:\Users\$currentUserName\Desktop\Post User Install.lnk"
$ShortcutCurrentUserPostUserInstall = $WshShell.CreateShortcut($shortcutPathCurrentUserPostUserInstall)
$ShortcutCurrentUserPostUserInstall.TargetPath = $targetPathPostUserInstall
$ShortcutCurrentUserPostUserInstall.IconLocation = $iconPathPostUserInstall
$ShortcutCurrentUserPostUserInstall.Description = "Shortcut to Post-User-Install Script"
$ShortcutCurrentUserPostUserInstall.Save()

# Create the shortcut for the Default user - Choco Apps
$shortcutPathDefaultChocoApps = "C:\Users\Default\Desktop\Choco Apps.lnk"
$ShortcutDefaultChocoApps = $WshShell.CreateShortcut($shortcutPathDefaultChocoApps)
$ShortcutDefaultChocoApps.TargetPath = $targetPathChocoApps
$ShortcutDefaultChocoApps.IconLocation = $iconPathChocoApps
$ShortcutDefaultChocoApps.Description = "Shortcut to Choco Apps Script"
$ShortcutDefaultChocoApps.Save()

# Create the shortcut for the current user - Choco Apps
$currentUserName = $env:USERNAME
$shortcutPathCurrentUserChocoApps = "C:\Users\$currentUserName\Desktop\Choco Apps.lnk"
$ShortcutCurrentUserChocoApps = $WshShell.CreateShortcut($shortcutPathCurrentUserChocoApps)
$ShortcutCurrentUserChocoApps.TargetPath = $targetPathChocoApps
$ShortcutCurrentUserChocoApps.IconLocation = $iconPathChocoApps
$ShortcutCurrentUserChocoApps.Description = "Shortcut to Choco Apps Script"
$ShortcutCurrentUserChocoApps.Save()

#-------------------------------------------------------------
# Copy a pristine start.bin to the default user profile
#-------------------------------------------------------------
# Define source and destination paths
$sourceFile = "C:\prep\NewWindowsScripts\start2.bin"
$destinationDir = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\"

# Check if the source file exists
if (Test-Path $sourceFile) {
    # Check if the destination directory exists, if not create it
    if (-Not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory
    }

    # Copy the file
    Copy-Item -Path $sourceFile -Destination $destinationDir -Force
} else {
    Write-Host "Source file does not exist."
}



$statusMessage = @"
Changes Applied:

1 - Bing Search has been Disabled
2 - Game Bar Tips has been disabled
3 - File extensions will be visible
4 - Taskbar Tweaks have been applied
5 - Registry Tweaks have been applied
6 - Shortcuts for New User Installs have been added

Press Enter to acknowledge.
"@

Write-Host $statusMessage
Read-Host