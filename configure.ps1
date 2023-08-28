# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Run the commands interactively
Disable-UAC -Confirm:$false
Disable-BingSearch
Disable-GameBarTips
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
Set-BoxstarterTaskbarOptions -Size Large -Dock Bottom -Combine Always -AlwaysShowIconsOn
