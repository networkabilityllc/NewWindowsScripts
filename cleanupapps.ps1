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
    '.*Microsoft.Winget.Source.*',                # Keep Winget integration

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

    # Modern Windows 11 Apps (renamed after 23H2)
    '.*Microsoft.WindowsNotepad.*',
    '.*Microsoft.WindowsFeedbackHub.*',
    '.*Microsoft.Windows.DevHome.*',
    '.*Microsoft.ZuneMusic.*',
    '.*Microsoft.SecHealthUI.*',
    '.*Microsoft.Windows.ShellExperienceHost.*',
    '.*Microsoft.Windows.StartMenuExperienceHost.*',
    '.*MicrosoftWindows.Client.Core.*',
    '.*MicrosoftWindows.Client.CBS.*',
    '.*MicrosoftWindows.Client.WebExperience.*',
    '.*MicrosoftWindows.Client.FileExp.*',
    '.*MicrosoftWindows.Client.Photon.*',
    '.*MicrosoftCorporationII.QuickAssist.*',
    '.*Microsoft.Win32WebViewHost.*',
    '.*Microsoft.AccountsControl.*',
    '.*Microsoft.LockApp.*',
    '.*Microsoft.CloudExperienceHost.*',
    '.*Microsoft.Windows.PeopleExperienceHost.*',
    '.*Microsoft.Windows.ContentDeliveryManager.*',
    '.*Microsoft.Windows.Apprep.ChxApp.*',

    # Core system and OOBE components
    '.*Microsoft.AAD.BrokerPlugin.*',
    '.*Microsoft.AsyncTextService.*',
    '.*Microsoft.BioEnrollment.*',
    '.*Microsoft.CredDialogHost.*',
    '.*Microsoft.ECApp.*',
    '.*Microsoft.Windows.AssignedAccessLockApp.*',
    '.*Microsoft.Windows.CapturePicker.*',
    '.*Microsoft.Windows.CloudExperienceHost.*',
    '.*Microsoft.Windows.NarratorQuickStart.*',
    '.*Microsoft.Windows.OOBENetworkCaptivePortal.*',
    '.*Microsoft.Windows.OOBENetworkConnectionFlow.*',
    '.*Microsoft.Windows.ParentalControls.*',
    '.*Microsoft.Windows.PinningConfirmationDialog.*',
    '.*Microsoft.Windows.SecureAssessmentBrowser.*',
    '.*Microsoft.Windows.XGpuEjectDialog.*',
    '.*MicrosoftWindows.Client.OOBE.*',
    '.*MicrosoftWindows.UndockedDevKit.*',
    '.*windows.immersivecontrolpanel.*',          # Modern Settings
    '.*MicrosoftWindows.CrossDevice.*',

    # Printing system (preserve Microsoft Print to PDF)
    '.*Windows.PrintDialog.*',
    '.*Microsoft.Windows.PrintQueueActionCenter.*',
    '.*Microsoft.Print3D.*',

    # System utilities
    '.*Microsoft.WindowsTerminal.*',
    '.*Microsoft.WindowsFeedbackHub.*',
    '.*Microsoft.ZuneVideo.*',
    '.*Clipchamp.Clipchamp.*',

    # Browser
    '.*Microsoft.MicrosoftEdge.Stable.*',         # Keep Edge browser
    # Critical GUID-based system apps
    '.*1527c705-839a-4832-9118-54d4bd6a0c89.*',
    '.*c5e2524a-ea46-4f67-841f-6a9465d9d515.*',
    '.*E2A4F912-2574-4A75-9BB0-0D023378592B.*',
) -join '|'

# Get all installed Appx packages for all users and filter out whitelisted ones
$unwantedApps = Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $excludedApps -and $_.IsFramework -eq $false }

# Remove unwanted apps or notify if none found
if ($unwantedApps) {
    $totalApps = $unwantedApps.Count
    Write-Output "Removing $totalApps unwanted apps..."
    
    $unwantedApps | ForEach-Object {
        Write-Output "Removing: $($_.Name)"
        $_ | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    
    Write-Output "App removal process completed."
} else {
    Write-Output "No unwanted apps found. No removals needed."
}

# End of script
