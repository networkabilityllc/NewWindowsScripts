# Path to git.exe
$gitPath = "C:\Program Files\Git\bin\git.exe"  # Change this path to the actual location of git.exe

Write-Host "Checking for Git installation." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"

# Check if the repository has been cloned
Write-Host "Checking if the repository has been cloned." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
$repoPath = "c:\prep\NewWindowsScripts"
if (-not (Test-Path -Path $repoPath)) {
    # Clone the GitHub repository
    $gitRepoUrl = "https://github.com/networkabilityllc/NewWindowsScripts"
    Start-Process -FilePath $gitPath -ArgumentList "clone", $gitRepoUrl, $repoPath
} else {
    # Update the repository
    Set-Location -Path $repoPath
    & $gitPath pull
}
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
# Check if Python is already installed
$pythonInstalled = Test-Path "C:\python310\python.exe"

# Check if Git is already installed
$gitInstalled = (Get-Command git -ErrorAction SilentlyContinue) -ne $null

# Install Python using Chocolatey if not already installed
if (-not $pythonInstalled) {
    & $chocoPath install python310 --force
}

# Install Git using Chocolatey if not already installed
if (-not $gitInstalled) {
    & C:\ProgramData\chocolatey\choco install git --force

    }



# Load the PresentationFramework assembly
# Add-Type -AssemblyName PresentationFramework

# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Run the commands interactively
# Check if UAC is already disabled
$uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue

# Only disable UAC if it's not already disabled
if ($uacStatus -eq $null -or $uacStatus.EnableLUA -ne 0) {
    Disable-UAC -Confirm:$false
    Write-Host "UAC has been disabled."
} else {
    Write-Host "UAC is already disabled."
}

# Check if Bing Search is already disabled
$bingSearchDisabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search").BingSearchEnabled -eq 0

# Output "Disabled" if already disabled, or run the command to disable it
if ($bingSearchDisabled) {
    "Bing Search is Already Disabled"
} else {
    # Run the command to disable Bing Search
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0 -Force
    "Bing Search is Now Disabled"
}


Disable-GameBarTips
Write-Host "Setting Enable Show Hiiden Files and Folders. Enabling Show File Extensions. Disabling Open File Explorer to Quick Access. Disabling Show Recent Files in Quick Access. Disabling Show Frequent Folders in Quick Access. Disabling Expand to Open Folder."
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions -DisableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess -DisableExpandToOpenFolder
Write-Host "Setting Taskbar size Large."
Set-BoxstarterTaskbarOptions -Size Large 
Set-BoxstarterTaskbarOptions -Dock Bottom 
Set-BoxstarterTaskbarOptions -DisableSearchBox 
Set-BoxstarterTaskbarOptions -AlwaysShowIconsOn 
Set-BoxstarterTaskbarOptions -Combine Always
#-------------------------------------------------------------
# Remove Taskbar Chat Icon
Write-Host "Removing Taskbar Chat Icon." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0
#-------------------------------------------------------------

#-------------------------------------------------------------
# Disable Windows Consumer Experience Features

Write-Host "Disabling Windows Consumer Experience Features." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
#-------------------------------------------------------------
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
# Restore the classic right-click context menu

Write-Host "Restoring the classic right-click context menu." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
# Set Mouse Hover Time for Taskbar to a very long time to prevent hover text
Write-Host "Setting Mouse Hover Time for Taskbar to a very long time to prevent hover text." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value 10000
# Set the registry value to show hidden files and folders for the current user
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Set the registry value to show hidden files and folders for all users
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "CheckedValue" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "DefaultValue" -Value 1


# Set the paths
$shortcutPath = "C:\Users\Default\Desktop\Post User Install.lnk"
$targetPath = "C:\prep\NewWindowsScripts\post-user-install.bat"
$iconPath = "C:\prep\NewWindowsScripts\installme.ico"

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath

# Set the shortcut's icon to the provided .ico file
$Shortcut.IconLocation = $iconPath

# Additional optional setting
$Shortcut.Description = "Shortcut to Post-User-Install Script"

# Save the shortcut
$Shortcut.Save()
#Requires -RunAsAdministrator

# ------------------------------------------------------------
# This section adds the "Open Command Prompt Here" option to
# the context menu when you right-click 
# ------------------------------------------------------------
#------------------------------------------------------------
# Because the next section opens a dialog box, which may
# open behind the current window, we need to display a
# message to the user to look for it
#------------------------------------------------------------

# Display a screen prompt to the user
Write-Host "Please look behind this console window for any open dialog boxes or user prompts.`nClose them before continuing." -ForegroundColor Black -BackgroundColor Blue
Write-Host "`n"
# ------------------------------------------------------------
# Add the "Open Command Prompt Here" option to the context menu
# ------------------------------------------------------------

# Import registry settings
regedit.exe /s "C:\prep\NewWindowsScripts\addprompts.reg"

# Display a message to the user
$popupMessage = "Right click to open Command Prompt added.`r`nShift-Right Click to open PowerShell and Elevated Command Prompt added.`r`nClick OK to continue."
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.MessageBox]::Show($popupMessage, "Notification", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

# ------------------------------------------------------------
# Turn on numlock at startup
# ------------------------------------------------------------
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NumLockControl {
    const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    const uint KEYEVENTF_KEYUP = 0x0002;
    const int VK_NUMLOCK = 0x90;

    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public static void EnableNumLock() {
        keybd_event((byte)VK_NUMLOCK, 0x45, KEYEVENTF_EXTENDEDKEY, (UIntPtr)0);
        keybd_event((byte)VK_NUMLOCK, 0x45, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, (UIntPtr)0);
    }
}
"@

[NumLockControl]::EnableNumLock()



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

    Write-Host "Git context menu entries removed from the registry."

#-------------------------------------------------------------
# Start App Cleanup Script
#-------------------------------------------------------------

$scriptPath = "C:\prep\NewWindowsScripts\cleanupapps.ps1"
Invoke-Expression -Command "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""

#-------------------------------------------------------------
# Make sure that WinGet is installed and if not, install it
#-------------------------------------------------------------
$packageName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe"

# Check if the package is installed
$package = Get-AppxPackage -Name $packageName -AllUsers

if ($package -eq $null) {
    # Package not found, install it
    Add-AppxPackage -RegisterByFamilyName -MainPackage $packageName
    Write-Host "Package '$packageName' installed."
} else {
    # Package is already installed
    Write-Host "Package '$packageName' is already installed."
}
#-------------------------------------------------------------
# Install the latest version of WinGet from GitHub
#-------------------------------------------------------------
Write-Host "Installing the latest version of WinGet from GitHub." -ForegroundColor Black -BackgroundColor White
Write-Host "`n"
# Define the URL and destination path
Write-host "This URL may change in the future - always check the latest release from https://github.com/microsoft/winget-cli/releases" -ForegroundColor Black -BackgroundColor White
Write-Host "`n"

$url = "https://github.com/microsoft/winget-cli/releases/download/v1.6.2631/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$destPath = "C:\Temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

# Create the destination directory if it doesn't exist
if (-Not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory
}

# Download the file
Invoke-WebRequest -Uri $url -OutFile $destPath

# Install the application silently
Add-AppxPackage -Path $destPath

#-------------------------------------------------------------
# Install Microsoft.UI.Xaml.2.8 using WinGet from the MS Store
Write-Host "Installing Microsoft.UI.Xaml.2.8 using WinGet." -ForegroundColor Black -BackgroundColor White
winget install Microsoft.UI.Xaml.2.8 --accept-source-agreements --accept-package-agreements

#-------------------------------------------------------------
# Uninstall Windows 11 Personal Teams
#-------------------------------------------------------------
Write-Host "Uninstalling Windows 11 Personal Teams." -ForegroundColor Black -BackgroundColor White
Get-AppxPackage -Name MicrosoftTeams -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

#-------------------------------------------------------------
# Start Chocolatey App Installer
#-------------------------------------------------------------
Write-Host "Starting Chocolatey App Installer." -ForegroundColor Black -BackgroundColor White
C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py

#-------------------------------------------------------------
# Install .Net 3.5 (Netfx3) using PowerShell
#-------------------------------------------------------------
#-------------------------------------------------------------
# Check for the presence of .NET 3.5 and install it if 
# it's not already installed. Suppress Local Media Missing
# error message.
#-------------------------------------------------------------
Write-Host "Installing .NET 3.5 (Netfx3) using PowerShell." -ForegroundColor Black -BackgroundColor White
$featureName = "NetFx3"
$sourcePath = "d:\sources\sxs"

# Check if the feature is enabled
$feature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $featureName }

if ($feature -eq $null -or $feature.State -ne "Enabled") {
    try {
        # Try enabling the feature from local source
        $enableFeature = Enable-WindowsOptionalFeature -FeatureName $featureName -Online -All -Source $sourcePath -LimitAccess -ErrorAction Stop
        Write-Host "Feature '$featureName' enabled."
    }
    catch {
        # Handle the error when local media is not found
        Write-Host "Local Media not available: Checking for Online Source."
        # Try enabling the feature from online source
        Enable-WindowsOptionalFeature -FeatureName $featureName -Online -All
    }
} else {
    # Feature is already enabled
    Write-Host "Feature '$featureName' is already enabled."
}


#-------------------------------------------------------------
# Add Boxstart Icon to the Default and the current User's Desktops
#-------------------------------------------------------------
Write-Host "Adding Boxstarter Shell shortcut to the Default and current user's Desktops." -ForegroundColor Black -BackgroundColor White
# Define the location for the shortcut for the Default User
$defaultUserShortcutPath = "C:\Users\Default\Desktop\Box Starter.lnk"

# Define the location for the shortcut for the current user
$currentuserShortcutPath = "$($env:USERPROFILE)\Desktop\Box Starter.lnk"

# Define the target PowerShell command
$command = 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Define the icon location
$iconLocation = "C:\ProgramData\Boxstarter\boxlogo.ico"

# Define the "Start In" (working directory) path
$startInPath = 'C:\ProgramData\Boxstarter\'

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut for the Default User
$ShortcutDefaultUser = $WshShell.CreateShortcut($defaultUserShortcutPath)
$ShortcutDefaultUser.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ShortcutDefaultUser.Arguments = "-ExecutionPolicy bypass -NoExit -File `"$command`""
$ShortcutDefaultUser.IconLocation = $iconLocation
$ShortcutDefaultUser.WorkingDirectory = $startInPath
$ShortcutDefaultUser.Save()

# Create the shortcut for the current user
$ShortcutCurrentUser = $WshShell.CreateShortcut($currentuserShortcutPath)
$ShortcutCurrentUser.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ShortcutCurrentUser.Arguments = "-ExecutionPolicy bypass -NoExit -File `"$command`""
$ShortcutCurrentUser.IconLocation = $iconLocation
$ShortcutCurrentUser.WorkingDirectory = $startInPath
$ShortcutCurrentUser.Save()

#-------------------------------------------------------------
# Remove the Boxstarter shortcut from the Public Folder
# that was created during the Boxstarter installation
#-------------------------------------------------------------
Write-Host "Removing Boxstarter Shell shortcut from Public Desktop." -ForegroundColor Black -BackgroundColor White

if (Test-Path "C:\Users\Public\Desktop\Boxstarter Shell.lnk") { Remove-Item -Path "C:\Users\Public\Desktop\Boxstarter Shell.lnk" }
write-host "Boxstarter Shell shortcut removed from Public Desktop."

#-------------------------------------------------------------
# Toggle UAC Section
# ------------------------------------------------------------ 
Write-Host "Toggling UAC." -ForegroundColor Black -BackgroundColor White
# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Function to toggle UAC
# Display a dialog box to ask if the user wants to re-enable UAC
$dialogResult = [System.Windows.Forms.MessageBox]::Show("Do you want to re-enable UAC?", "UAC Re-enable", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    Enable-UAC
    Write-Host "UAC has been re-enabled."
} else {
    Write-Host "UAC remains disabled."
}