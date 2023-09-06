# ------------------------------------------------------------
# Set the apps to be excluded from the removal script
# ------------------------------------------------------------
$excludedApps = '.*photos.*|.*calculator.*|.*alarms.*|.*sticky.*|.*soundrecorder.*|.*zunevideo.*|.*microsoft.desktopappinstaller.*|.*store.*|.*notepad.*|.*terminal.*|.*translucent*'
# ------------------------------------------------------------
# In some cases, the app removval function below does not 
# remove Spotify, Teams or Movies & TV. Add them to the list
# Also, sometimes Windows just ignores the removal request 
# ¯\_(ツ)_/¯  - we will look into this later
# ------------------------------------------------------------
$additionalApps = @(
    '*spotify*',
    '*teams*',
    '*moviesandtv*'
)
# ------------------------------------------------------------
# This section creates a list of apps to be removed by 
# enumerating all apps and then removing the ones that are
# not in the $excludedApps list
# ------------------------------------------------------------
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

# Requires -RunAsAdministrator
# ------------------------------------------------------------
# This section removes the apps from the start menu. Sort of.
# We need to attribute this to the original author, but we
# have to research who that is.
# ------------------------------------------------------------

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
Stop-Process -name explorer
Start-Sleep -s 5
$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
Start-Sleep -s 5

#Enable the ability to pin items again by disabling "LockedStartLayout"
foreach ($regAlias in $regAliases){
    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath = $basePath + "\Explorer" 
    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
}

#Restart Explorer and delete the layout file
Stop-Process -name explorer

# Uncomment the next line to make clean start menu default for all new users
Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\

Remove-Item $layoutFile


