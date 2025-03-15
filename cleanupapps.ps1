# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You need to run this script as an Administrator."
    exit 1
}

# Set the apps to be excluded from the removal script.
# This acts as a whitelist to prevent removing essential apps.
$excludedApps = @(
    '.*photos.*',
    '.*calculator.*',
    '.*alarms.*',
    '.*sticky.*',
    '.*soundrecorder.*',
    '.*zunevideo.*',
    '.*microsoft.desktopappinstaller.*',
    '.*store.*',
    '.*notepad.*',
    '.*terminal.*',
    '.*translucent*',
    '.*Microsoft.VCLibs.*',
    '.*Microsoft.NET.Native.Framework.*',
    '.*Microsoft.UI.Xaml.*',
    '.*Microsoft.WindowsCalculator.*',
    '.*Microsoft.WindowsStore.*',
    '.*Microsoft.HEIFImageExtension.*',
    '.*Microsoft.AV1VideoExtension.*',
    '.*Microsoft.Print3D.*',
    '.*Microsoft.ScreenSketch.*',
    '.*Microsoft.WindowsFeedbackHub.*',
    '.*Microsoft.XboxGameOverlay.*',
    '.*Microsoft.XboxGamingOverlay.*',
    '.*Microsoft.XboxIdentityProvider.*',
    '.*Microsoft.XboxSpeechToTextOverlay.*',
    '.*Microsoft.YourPhone.*',
    '.*Microsoft.Windows.Photos.*',
    '.*Microsoft.HEVCVideoExtension.*',
    '.*Microsoft.Paint.*',
    '.*Microsoft.VP9VideoExtensions.*',
    '.*Microsoft.WindowsSoundRecorder.*',
    '.*Microsoft.RawImageExtension.*',
    '.*Microsoft.WebpImageExtension.*',
    '.*Clipchamp.Clipchamp.*'
) -join '|' # Join the array elements with '|' to create a regex pattern for matching excluded apps

# Get only removable Appx bundles and filter them
$unwantedApps = Get-AppxPackage -PackageTypeFilter Bundle | Where-Object { $_.Name -notmatch $excludedApps }

# Remove unwanted apps or notify if none found
if ($unwantedApps) {
    $totalApps = $unwantedApps.Count
    Write-Output "Removing $totalApps unwanted apps..."
    
    $unwantedApps | ForEach-Object {
        Write-Output "Removing: $($_.Name)"
        $_ | Remove-AppxPackage
    }
    
    Write-Output "App removal process completed."
} else {
    Write-Output "No unwanted apps found. No removals needed."
}
# End of script