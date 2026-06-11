# Repair-OneDriveExplorerNamespace.ps1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Guid[]]$TargetClsid,
    [switch]$NoExplorerRestart
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Convert-ToRegExePath {
    param([Parameter(Mandatory)][string]$Path)

    return $Path `
        -replace '^HKLM:\\', 'HKLM\' `
        -replace '^HKCU:\\', 'HKCU\'
}

function Convert-ToPsPath {
    param([Parameter(Mandatory)][string]$Path)

    return $Path `
        -replace '^HKLM\\', 'HKLM:\' `
        -replace '^HKCU\\', 'HKCU:\'
}

function Get-DefaultValue {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        return $null
    }

    return (Get-Item -Path $Path).GetValue("")
}

function Set-DefaultValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Value
    )

    $regPath = Convert-ToRegExePath -Path $Path

    if ($PSCmdlet.ShouldProcess($regPath, "Set default value to '$Value'")) {
        & reg.exe add $regPath /ve /d $Value /f | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed setting default value on $regPath"
        }
    }
}

function Set-StringValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set string value")) {
        New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
    }
}

function Set-DwordValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][UInt32]$Value
    )

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set DWORD value to $Value")) {
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
    }
}

function New-Key {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Create registry key")) {
            New-Item -Path $Path -Force | Out-Null
        }
    }
}

function Export-KeyIfPresent {
    param(
        [Parameter(Mandatory)][string]$RegPath,
        [Parameter(Mandatory)][string]$OutputFile
    )

    $psPath = Convert-ToPsPath -Path $RegPath

    if (Test-Path $psPath) {
        $output = & reg.exe export $RegPath "$OutputFile" /y 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Backed up: $RegPath"
        }
        else {
            Write-Warning "Failed to export: $RegPath"
            Write-Warning ($output | Out-String)
        }
    }
    else {
        $missingFile = [System.IO.Path]::ChangeExtension($OutputFile, ".missing.txt")
        "Registry key did not exist before repair: $RegPath" | Set-Content -Path $missingFile -Encoding UTF8
        Write-Host "Missing before repair: $RegPath"
    }
}

function Find-OneDriveExe {
    $candidates = @(
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    )

    return $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

function Test-OneDriveNamespaceShape {
    param([Parameter(Mandatory)][string]$BasePath)

    $required = @(
        "$BasePath\Instance",
        "$BasePath\Instance\InitPropertyBag",
        "$BasePath\ShellFolder"
    )

    foreach ($path in $required) {
        if (-not (Test-Path $path)) {
            return $false
        }
    }

    $instance = Get-ItemProperty "$BasePath\Instance" -ErrorAction SilentlyContinue
    $bag = Get-ItemProperty "$BasePath\Instance\InitPropertyBag" -ErrorAction SilentlyContinue
    $shell = Get-ItemProperty "$BasePath\ShellFolder" -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($instance.CLSID)) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($bag.TargetKnownFolder)) {
        return $false
    }

    if ($null -eq $bag.Attributes) {
        return $false
    }

    if ($null -eq $shell.Attributes) {
        return $false
    }

    return $true
}

function Get-OneDriveNamespaceCandidates {
    $searchRoots = @(
        "HKCU:\Software\Classes\CLSID",
        "HKCU:\Software\Classes\WOW6432Node\CLSID"
    )

    $results = @{}

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }

        Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
            $clsid = $_.PSChildName
            $basePath = $_.PSPath

            if ($TargetClsid -and ($TargetClsid.Guid -notcontains $clsid.Trim("{}"))) {
                return
            }

            if (-not (Test-OneDriveNamespaceShape -BasePath $basePath)) {
                return
            }

            $displayName = Get-DefaultValue -Path $basePath
            $desktopNamePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$clsid"
            $desktopName = Get-DefaultValue -Path $desktopNamePath
            $icon = Get-DefaultValue -Path "$basePath\DefaultIcon"

            $looksLikeOneDrive =
                ($displayName -like "OneDrive*") -or
                ($desktopName -like "OneDrive*") -or
                ($icon -match '\\Microsoft OneDrive\\OneDrive\.exe')

            if (-not $looksLikeOneDrive) {
                return
            }

            if (-not $results.ContainsKey($clsid)) {
                $results[$clsid] = [pscustomobject]@{
                    Clsid             = $clsid
                    SourcePath        = $basePath
                    DesktopNamePath   = $desktopNamePath
                    DisplayName       = $displayName
                    DesktopName       = $desktopName
                    DefaultIcon       = $icon
                }
            }
        }
    }

    return $results.Values
}

function Read-NamespaceValues {
    param(
        [Parameter(Mandatory)][object]$Candidate,
        [string]$OneDriveExe
    )

    $base = $Candidate.SourcePath

    $instancePath = "$base\Instance"
    $bagPath = "$base\Instance\InitPropertyBag"
    $shellPath = "$base\ShellFolder"
    $iconPath = "$base\DefaultIcon"

    $root = Get-ItemProperty $base
    $instance = Get-ItemProperty $instancePath
    $bag = Get-ItemProperty $bagPath
    $shell = Get-ItemProperty $shellPath

    $displayName = $Candidate.DisplayName
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = $Candidate.DesktopName
    }
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        throw "CLSID $($Candidate.Clsid) has no usable display name in HKCU."
    }

    $desktopName = $Candidate.DesktopName
    if ([string]::IsNullOrWhiteSpace($desktopName)) {
        $desktopName = $displayName
    }

    $defaultIcon = Get-DefaultValue -Path $iconPath
    if ([string]::IsNullOrWhiteSpace($defaultIcon)) {
        if ([string]::IsNullOrWhiteSpace($OneDriveExe)) {
            throw "CLSID $($Candidate.Clsid) has no DefaultIcon and OneDrive.exe could not be located."
        }
        $defaultIcon = "$OneDriveExe,5"
    }

    [pscustomobject]@{
        Clsid                   = $Candidate.Clsid
        DisplayName             = $displayName
        DesktopName             = $desktopName
        DefaultIcon             = $defaultIcon
        InProcServer32          = "$env:SystemRoot\system32\shell32.dll"
        InstanceClsid           = [string]$instance.CLSID
        TargetKnownFolder       = [string]$bag.TargetKnownFolder
        InitAttributes          = [UInt32]$bag.Attributes
        ShellFolderAttributes   = [UInt32]$shell.Attributes
        FolderValueFlags        = if ($null -ne $shell.FolderValueFlags) { [UInt32]$shell.FolderValueFlags } else { $null }
        SortOrderIndex          = if ($null -ne $root.SortOrderIndex) { [UInt32]$root.SortOrderIndex } else { $null }
        IsPinned                = if ($null -ne $root.'System.IsPinnedToNameSpaceTree') { [UInt32]$root.'System.IsPinnedToNameSpaceTree' } else { [UInt32]1 }
    }
}

function Repair-Namespace {
    param(
        [Parameter(Mandatory)][object]$Values,
        [Parameter(Mandatory)][string]$BasePath
    )

    $defaultIconPath = "$BasePath\DefaultIcon"
    $inProcPath = "$BasePath\InProcServer32"
    $instancePath = "$BasePath\Instance"
    $bagPath = "$BasePath\Instance\InitPropertyBag"
    $shellPath = "$BasePath\ShellFolder"

    foreach ($path in @(
        $BasePath,
        $defaultIconPath,
        $inProcPath,
        $instancePath,
        $bagPath,
        $shellPath
    )) {
        New-Key -Path $path
    }

    Set-DefaultValue -Path $BasePath -Value $Values.DisplayName
    Set-DwordValue -Path $BasePath -Name "System.IsPinnedToNameSpaceTree" -Value $Values.IsPinned

    if ($null -ne $Values.SortOrderIndex) {
        Set-DwordValue -Path $BasePath -Name "SortOrderIndex" -Value $Values.SortOrderIndex
    }

    Set-DefaultValue -Path $defaultIconPath -Value $Values.DefaultIcon
    Set-DefaultValue -Path $inProcPath -Value $Values.InProcServer32

    Set-StringValue -Path $instancePath -Name "CLSID" -Value $Values.InstanceClsid
    Set-DwordValue -Path $bagPath -Name "Attributes" -Value $Values.InitAttributes
    Set-StringValue -Path $bagPath -Name "TargetKnownFolder" -Value $Values.TargetKnownFolder

    if ($null -ne $Values.FolderValueFlags) {
        Set-DwordValue -Path $shellPath -Name "FolderValueFlags" -Value $Values.FolderValueFlags
    }

    Set-DwordValue -Path $shellPath -Name "Attributes" -Value $Values.ShellFolderAttributes
}

function Test-RepairedNamespace {
    param(
        [Parameter(Mandatory)][string]$BasePath
    )

    $required = @(
        $BasePath,
        "$BasePath\DefaultIcon",
        "$BasePath\InProcServer32",
        "$BasePath\Instance",
        "$BasePath\Instance\InitPropertyBag",
        "$BasePath\ShellFolder"
    )

    foreach ($path in $required) {
        if (-not (Test-Path $path)) {
            return $false
        }
    }

    return $true
}

if (-not (Test-IsAdministrator)) {
    throw "Run this script from an elevated PowerShell session."
}

$oneDriveExe = Find-OneDriveExe
$candidates = @(Get-OneDriveNamespaceCandidates)

if ($candidates.Count -eq 0) {
    throw "No repairable OneDrive namespace CLSIDs were found in HKCU. This script repairs the HKLM-missing/HKCU-present condition only."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $env:USERPROFILE "Desktop\OneDrive-Namespace-Backup-$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

Write-Host "Discovered repairable OneDrive namespace CLSIDs:"
foreach ($candidate in $candidates) {
    Write-Host "  $($candidate.Clsid) : $($candidate.DisplayName)"
}
Write-Host ""
Write-Host "Backup directory:"
Write-Host "  $backupDir"
Write-Host ""

$results = foreach ($candidate in $candidates) {
    try {
        $values = Read-NamespaceValues -Candidate $candidate -OneDriveExe $oneDriveExe

        $nativePath = "HKLM:\SOFTWARE\Classes\CLSID\$($values.Clsid)"
        $wowPath = "HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\$($values.Clsid)"
        $desktopPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$($values.Clsid)"

        Export-KeyIfPresent `
            -RegPath "HKLM\SOFTWARE\Classes\CLSID\$($values.Clsid)" `
            -OutputFile (Join-Path $backupDir "HKLM-Classes-CLSID-$($values.Clsid).reg")

        Export-KeyIfPresent `
            -RegPath "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\$($values.Clsid)" `
            -OutputFile (Join-Path $backupDir "HKLM-Classes-WOW6432Node-CLSID-$($values.Clsid).reg")

        Export-KeyIfPresent `
            -RegPath "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$($values.Clsid)" `
            -OutputFile (Join-Path $backupDir "HKLM-Desktop-NameSpace-$($values.Clsid).reg")

        Repair-Namespace -Values $values -BasePath $nativePath
        Repair-Namespace -Values $values -BasePath $wowPath

        New-Key -Path $desktopPath
        Set-DefaultValue -Path $desktopPath -Value $values.DesktopName

        $nativeOk = Test-RepairedNamespace -BasePath $nativePath
        $wowOk = Test-RepairedNamespace -BasePath $wowPath
        $desktopOk = Test-Path $desktopPath

        [pscustomobject]@{
            Clsid       = $values.Clsid
            DisplayName = $values.DisplayName
            NativeHKLM  = $nativeOk
            WowHKLM     = $wowOk
            DesktopHKLM = $desktopOk
            Status      = if ($nativeOk -and $wowOk -and $desktopOk) { "Repaired" } else { "Incomplete" }
            Error       = $null
        }
    }
    catch {
        [pscustomobject]@{
            Clsid       = $candidate.Clsid
            DisplayName = $candidate.DisplayName
            NativeHKLM  = $false
            WowHKLM     = $false
            DesktopHKLM = $false
            Status      = "Failed"
            Error       = $_.Exception.Message
        }
    }
}

Write-Host ""
Write-Host "Repair summary:"
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -ne "Repaired" })

if (-not $NoExplorerRestart) {
    Write-Host "Restarting Explorer..."
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
}

if ($failed.Count -gt 0) {
    exit 1
}

exit 0