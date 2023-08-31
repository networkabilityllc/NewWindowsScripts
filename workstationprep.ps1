# Create directory and navigate to it
$prepDir = "C:\prep"
if (-not (Test-Path $prepDir)) {
    New-Item -Path $prepDir -ItemType Directory
}
Set-Location -Path $prepDir
# Set Execution Policy
Set-ExecutionPolicy Bypass -Scope LocalMachine -Force

# Download necessary files
# Invoke-WebRequest -Uri "https://pastebin.com/raw/rnRbp37h" -OutFile "run-choco.bat"
# Invoke-WebRequest -Uri "https://pastebin.com/raw/tH3ynJJg" -OutFile "get-choco.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/run-choco.bat" -OutFile "run-choco.bat"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/get-choco.ps1" -OutFile "get-choco.ps1"



# Execute run-choco.bat
Start-Process -Wait -FilePath "run-choco.bat"

# Path to Chocolatey executable
$chocoPath = "C:\ProgramData\chocolatey\choco.exe"  # Change this path to the actual location of choco.exe

# Install Python using Chocolatey
& $chocoPath install python310 --force

# Install Git using Chocolatey
& $chocoPath install git --force

# Check if the machine is running as a VMware virtual machine
$vmwareVm = Get-WmiObject -Namespace "root\cimv2" -Class Win32_ComputerSystem | Where-Object { $_.Manufacturer -eq "VMware, Inc." }

if ($vmwareVm) {
    Write-Host "Detected VMware virtual machine. Installing VMware Tools..."
    & $chocoPath install vmware-tools --force
} else {
    Write-Host "Not running as a VMware virtual machine. Skipping VMware Tools installation."
}



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

# Load the PresentationFramework assembly
Add-Type -AssemblyName PresentationFramework

# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Run the commands interactively
Disable-UAC -Confirm:$false
Disable-BingSearch
Disable-GameBarTips
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
Set-BoxstarterTaskbarOptions -Size Large -Dock Bottom -Combine Always -AlwaysShowIconsOn
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value 10000

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
