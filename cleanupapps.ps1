# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You need to run this script as an Administrator."
    exit 1
}

# Set the apps to be excluded from the removal script.
# This acts as a whitelist to prevent removing essential apps.
$excludedApps = @(
    # Core runtimes and frameworks
    '.*Microsoft.VCLibs.*',
    '.*Microsoft.NET.Native.Framework.*',
    '.*Microsoft.NET.Native.Runtime.*',
    '.*Microsoft.UI.Xaml.*',
    '.*Microsoft.WindowsAppRuntime.*',
    '.*Microsoft.WinAppRuntime.*',

    # App installer and store dependencies
    '.*Microsoft.DesktopAppInstaller.*',
    '.*Microsoft.StorePurchaseApp.*',
    '.*Microsoft.Services.Store.Engagement.*',
    '.*Microsoft.WindowsStore.*',

    # Core user apps
    '.*Microsoft.WindowsCalculator.*',
    '.*Microsoft.Windows.Photos.*',
    '.*Microsoft.WindowsSoundRecorder.*',
    '.*Microsoft.Paint.*',
    '.*Microsoft.Notepad.*',
    '.*Microsoft.WindowsCamera.*',
    '.*Microsoft.ScreenSketch.*',
    '.*Microsoft.FeedbackHub.*',
    '.*Microsoft.YourPhone.*',
    '.*Microsoft.OutlookForWindows.*',
    '.*Microsoft.DevHome.*',

    # Video and image codecs
    '.*Microsoft.HEIFImageExtension.*',
    '.*Microsoft.HEVCVideoExtension.*',
    '.*Microsoft.AV1VideoExtension.*',
    '.*Microsoft.RawImageExtension.*',
    '.*Microsoft.WebpImageExtension.*',
    '.*Microsoft.VP9VideoExtensions.*',

    # Xbox and gaming dependencies (needed by Store)
    '.*Microsoft.XboxGameOverlay.*',
    '.*Microsoft.XboxGamingOverlay.*',
    '.*Microsoft.XboxIdentityProvider.*',
    '.*Microsoft.XboxSpeechToTextOverlay.*',

    # System utilities
    '.*Microsoft.WindowsTerminal.*',
    '.*Microsoft.WindowsFeedbackHub.*',
    '.*Microsoft.ZuneVideo.*',
    '.*Clipchamp.Clipchamp.*',
    '.*Microsoft.Print3D.*'
) -join '|'

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