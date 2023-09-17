# Set the apps to be excluded from the removal script
# This is kind-of a whitelist. These are apps that should not be removed
# because doing so causes problems with Windows
$excludedApps = '.*photos.*|.*calculator.*|.*alarms.*|.*sticky.*|.*soundrecorder.*|.*zunevideo.*|.*microsoft.desktopappinstaller*|.*store.*|.*notepad.*|.*terminal.*|.*translucent*'

# This section creates a list of apps to be removed by 
# enumerating all apps and then removing the ones that are
# not in the $excludedApps list
$unwantedApps = Get-AppxPackage -PackageTypeFilter Bundle | Where-Object { $_.Name -notmatch $excludedApps }

# Remove the unwanted apps
if ($unwantedApps) {
    $unwantedApps | Remove-AppxPackage
}
