# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Run the commands interactively
Disable-UAC -Confirm:$false
Disable-BingSearch
Disable-GameBarTips
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
Set-BoxstarterTaskbarOptions -Size Large -Dock Bottom -Combine Always -AlwaysShowIconsOn
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

# Set the paths
$shortcutPath = "C:\Users\Default\Desktop\Run After User Setup.lnk"
$targetPath = "C:\prep\NewWindowsScripts\post-user-install.bat"

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath

# Additional optional settings
$Shortcut.Description = "Shortcut to Post-User-Install Script"
$Shortcut.IconLocation = "$env:SystemRoot\System32\imageres.dll,2" # Example icon, you can change this

# Save the shortcut
$Shortcut.Save()

