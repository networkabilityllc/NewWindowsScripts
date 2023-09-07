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
# ------------------------------------------------------------
# Download Splashtop SOS to c:\users\default\Desktop so that new users will have it available
# ------------------------------------------------------------
Invoke-WebRequest -Uri 'https://download.splashtop.com/sos/SplashtopSOS.exe' -OutFile 'C:\Users\Default\Desktop\SplashtopSOS.exe'
Write-Host "------------------------------------------"
Write-Host "Splashtop SOS installed for All New Users"
Write-Host "------------------------------------------"

# ----------------------------- Test for Choco and BoxStarter -------------------
Write-Host "------------------------------------------"
Write-Host "Checking for Choco and BoxStarter"
Write-Host "------------------------------------------"

# ------------------------------------------------------------
# Set the path to the chocolatey executable as an environment variable
# ------------------------------------------------------------
# Path to Chocolatey executable
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"  # Change this path to the actual location of choco.exe
# ------------------------------------------------------------
# Install Chocolatey if not already installed
# ------------------------------------------------------------
$chocoInstalled = (Get-Command choco -ErrorAction SilentlyContinue) -ne $null

if (-not $chocoInstalled) {
    # Install Chocolatey
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	# ------------------------------------------------------------
	# Note: this path declaration has to be here because the previous iex command invokes a powershell
	# session that does not have the previous declaration. Without it, the commands will fail
	# ------------------------------------------------------------
	$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
    # Enable global confirmation for Chocolatey
    & $chocoPath feature enable -n allowGlobalConfirmation
}

# ------------------------------------------------------------
# Path to Chocolatey executable declared again because the previous iex flushed the declaration sometimes
# ------------------------------------------------------------
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
# Install Boxstarter using Chocolatey
& $chocoPath install boxstarter --force

# ------------------------------------------------------------
# Version 0.9 of this script uses Python 3.10.6 to present a 
# checkbox screen for installing apps from chocolatey
# This will probably be changed to pure Powershell later
# Check if Python is already installed
# ------------------------------------------------------------
$pythonInstalled = Test-Path "C:\python310\python.exe"

# ------------------------------------------------------------
# This version of the script clones the repository using git
# We may remove git later or figure out a way to not have it 
# add itself to the context menu 
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

    Write-Host "Git context menu entries removed from the registry."
}

# ------------------------------------------------------------
# Check if the machine is running as a VMware virtual machine
# ------------------------------------------------------------
$vmwareVm = Get-WmiObject -Namespace "root\cimv2" -Class Win32_ComputerSystem | Where-Object { $_.Manufacturer -eq "VMware, Inc." }

if ($vmwareVm) {
    Write-Host "Detected VMware virtual machine. Installing VMware Tools..."
    & $chocoPath install vmware-tools --force
} else {
    Write-Host "Not running as a VMware virtual machine. Skipping VMware Tools installation."
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
    # Clone the GitHub repository
    $gitRepoUrl = "https://github.com/networkabilityllc/NewWindowsScripts"
    Start-Process -FilePath $gitPath -ArgumentList "clone", $gitRepoUrl, $repoPath
} else {
	# ------------------------------------------------------------
	# If already cloned, do a git pull to refresh it in case we 
    # changed something
    # ------------------------------------------------------------
    # Update the repository
	
    Set-Location -Path $repoPath
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
Disable-UAC -Confirm:$false
Disable-BingSearch
Disable-GameBarTips
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
# ------------------------------------------------------------
# This sections add the "Open Command Prompt Here" option to
# the context menu when you right-click 
# ------------------------------------------------------------
# Create the "Open Command Prompt Here" option
New-Item -Path "HKLM:\SOFTWARE\Classes\Directory\Background\shell\OpenCmdHere" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\Background\shell\OpenCmdHere" -Name "MUIVerb" -Value "Open Command Prompt Here"
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\Background\shell\OpenCmdHere" -Name "Icon" -Value "cmd.exe"

# Create the "command" subkey with the appropriate command
$commandKeyPath = "HKLM:\SOFTWARE\Classes\Directory\Background\shell\OpenCmdHere\command"
New-Item -Path $commandKeyPath -Force
Set-ItemProperty -Path $commandKeyPath -Name "(Default)" -Value 'cmd.exe /s /k "pushd \"%V\""'


# ------------------------------------------------------------
# This section creates a shortcut on the desktop for the
# Post User Install script. This script will be run by the
# domain admin after the user logs in for the first time.
# It repeats some of the settings above, because many of
# the above settings are not global and only apply to the
# user that is logged in when they are applied.
# We will probably be adding some code that creates the
# post-user install shortcut to the current user's desktop
# ------------------------------------------------------------
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