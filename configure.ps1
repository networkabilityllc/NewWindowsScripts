# Path to git.exe
$gitPath = "C:\Program Files\Git\bin\git.exe"  # Change this path to the actual location of git.exe

# Check if the repository has been cloned
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
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions -DisableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess -DisableExpandToOpenFolder
Set-BoxstarterTaskbarOptions -Size Large 
Set-BoxstarterTaskbarOptions -Dock Bottom 
Set-BoxstarterTaskbarOptions -DisableSearchBox 
Set-BoxstarterTaskbarOptions -AlwaysShowIconsOn 
Set-BoxstarterTaskbarOptions -Combine Always
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
# Restore the classic right-click context menu
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
# Set Mouse Hover Time for Taskbar to a very long time to prevent hover text
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
Write-Host "Please look behind this console window for any open dialog boxes or user prompts.`nClose them before continuing."

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

$START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

$layoutFile="C:\Windows\StartMenuLayout.xml"

#Delete layout file if it already exists
If(Test-Path $layoutFile)
{
    Remove-Item $layoutFile
}

#Creates the blank layout file
$START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

$regAliases = @("HKLM", "HKCU")

#Assign the start layout and force it to apply with "LockedStartLayout" at both the machine and user level
foreach ($regAlias in $regAliases){
    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath = $basePath + "\Explorer" 
    IF(!(Test-Path -Path $keyPath)) { 
        New-Item -Path $basePath -Name "Explorer"
    }
    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
    Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
}

#Restart Explorer, open the start menu (necessary to load the new layout), and give it a few seconds to process
Stop-Process -name explorer -force
Start-Sleep -Seconds 5
$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
Start-Sleep -s 5

#Enable the ability to pin items again by disabling "LockedStartLayout"
foreach ($regAlias in $regAliases){
    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath = $basePath + "\Explorer" 
    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
}

#Restart Explorer and delete the layout file
Stop-Process -name explorer -force

# Uncomment the next line to make clean start menu default for all new users
Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\

Remove-Item $layoutFile

C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py