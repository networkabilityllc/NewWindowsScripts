$excludedApps = '.*photos.*|.*calculator.*|.*alarms.*|.*sticky.*|.*soundrecorder.*|.*zunevideo.*|.*microsoft.desktopappinstaller.*'

$additionalApps = @(
    '*spotify*',
    '*teams*',
    '*moviesandtv*'
)

$unwantedApps = Get-AppxPackage -PackageTypeFilter Bundle | Where-Object { $_.Name -notmatch $excludedApps }

# Add the additional apps to the list of unwanted apps
$additionalApps | ForEach-Object {
    $additionalApp = $_
    $additionalUnwantedApp = Get-AppxPackage | Where-Object { $_.Name -like $additionalApp }
    if ($additionalUnwantedApp) {
        $unwantedApps += $additionalUnwantedApp
    }
}

if ($unwantedApps) {
    $unwantedApps | Remove-AppxPackage
}
