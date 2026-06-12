# Fix-KB5094126-OneDriveExplorerNamespace.ps1
# Repairs OneDrive Explorer navigation namespace registrations broken by KB5094126-style HKLM loss/corruption.
#
# Model:
#   - HKCU Desktop\NameSpace is treated as the active user-visible source of truth.
#   - HKCU Software\Classes\CLSID is treated as the source payload.
#   - HKLM Software\Classes\CLSID and HKLM Explorer Desktop\NameSpace are rebuilt from HKCU.
#   - Supports:
#       Personal/KFM OneDrive namespaces using TargetKnownFolder
#       Business/cloud-path OneDrive namespaces using TargetFolderPath
#       Multiple Personal/Business OneDrive namespaces
#
# Run elevated as the affected user.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$TargetClsid,
    [switch]$NoExplorerRestart
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Convert-ToRegExePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path `
        -replace '^HKLM:\\', 'HKLM\' `
        -replace '^HKCU:\\', 'HKCU\'
}

function Convert-ToPsPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path `
        -replace '^HKLM\\', 'HKLM:\' `
        -replace '^HKCU\\', 'HKCU:\'
}

function Get-RegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [AllowEmptyString()]
        [string]$Name = ""
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    return (Get-Item -Path $Path).GetValue($Name, $null)
}

function Get-RegistryValueKind {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [AllowEmptyString()]
        [string]$Name = ""
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    try {
        return (Get-Item -Path $Path).GetValueKind($Name)
    }
    catch {
        return $null
    }
}

function Set-RegistryValueNative {
    param(
        [Parameter(Mandatory)]
        [string]$KeyPath,

        [AllowEmptyString()]
        [string]$ValueName = "",

        [Parameter(Mandatory)]
        [ValidateSet("REG_SZ", "REG_EXPAND_SZ", "REG_DWORD")]
        [string]$Type,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    $regKey = Convert-ToRegExePath -Path $KeyPath
    $args = @("add", $regKey, "/f")

    if ([string]::IsNullOrEmpty($ValueName)) {
        $args += "/ve"
    }
    else {
        $args += @("/v", $ValueName)
    }

    $args += @("/t", $Type, "/d", $Value)

    if ($PSCmdlet.ShouldProcess($regKey, "Set '$ValueName' as $Type")) {
        & reg.exe @args | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "reg.exe failed while writing value '$ValueName' to $regKey"
        }
    }
}

function Remove-RegistryValueNative {
    param(
        [Parameter(Mandatory)]
        [string]$KeyPath,

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    if (-not (Test-Path $KeyPath)) {
        return
    }

    $regKey = Convert-ToRegExePath -Path $KeyPath

    if ($PSCmdlet.ShouldProcess($regKey, "Delete value '$ValueName'")) {
        & reg.exe delete $regKey /v $ValueName /f 2>$null | Out-Null
    }
}

function Export-KeyIfPresent {
    param(
        [Parameter(Mandatory)]
        [string]$RegPath,

        [Parameter(Mandatory)]
        [string]$OutputFile
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

function Convert-RegistryKindToRegExeType {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Win32.RegistryValueKind]$Kind
    )

    switch ($Kind) {
        "ExpandString" { return "REG_EXPAND_SZ" }
        "DWord"        { return "REG_DWORD" }
        default        { return "REG_SZ" }
    }
}

function Convert-DwordForRegExe {
    param(
        [Parameter(Mandatory)]
        $Value
    )

    return ([UInt32]$Value).ToString()
}

function Find-OneDriveExe {
    $candidates = @(
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    )

    return $candidates |
        Where-Object { $_ -and (Test-Path $_) } |
        Select-Object -First 1
}

function Get-OneDriveAccountCount {
    $accountsRoot = "HKCU:\Software\Microsoft\OneDrive\Accounts"

    if (-not (Test-Path $accountsRoot)) {
        return 0
    }

    return @(
        Get-ChildItem $accountsRoot -ErrorAction SilentlyContinue |
            Where-Object {
                $_.PSChildName -match '^(Personal|Business\d*)$'
            }
    ).Count
}

function Get-OneDriveNamespaceCandidates {
    $desktopRoot = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"

    if (-not (Test-Path $desktopRoot)) {
        return @()
    }

    $results = @{}

    Get-ChildItem $desktopRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $clsid = $_.PSChildName

        if ($TargetClsid -and
            ($TargetClsid -notcontains $clsid) -and
            ($TargetClsid -notcontains $clsid.Trim("{}"))) {
            return
        }

        $desktopName = [string](Get-RegistryValue -Path $_.PSPath)

        $sourcePath = "HKCU:\Software\Classes\CLSID\$clsid"
        if (-not (Test-Path $sourcePath)) {
            $sourcePath = "HKCU:\Software\Classes\WOW6432Node\CLSID\$clsid"
        }

        if (-not (Test-Path $sourcePath)) {
            return
        }

        $displayName = [string](Get-RegistryValue -Path $sourcePath)
        $icon = [string](Get-RegistryValue -Path "$sourcePath\DefaultIcon")

        $looksLikeOneDrive =
            ($desktopName -like "*OneDrive*") -or
            ($displayName -like "*OneDrive*") -or
            ($icon -match '\\Microsoft OneDrive\\OneDrive\.exe')

        if (-not $looksLikeOneDrive) {
            return
        }

        if (-not $results.ContainsKey($clsid)) {
            $results[$clsid] = [pscustomobject]@{
                Clsid           = $clsid
                SourcePath      = $sourcePath
                DesktopNamePath = $_.PSPath
                DisplayName     = if (-not [string]::IsNullOrWhiteSpace($displayName)) { $displayName } else { $desktopName }
                DesktopName     = $desktopName
                DefaultIcon     = $icon
            }
        }
    }

    return @($results.Values) | Where-Object { $null -ne $_ }
}

function Read-NamespaceValues {
    param(
        [Parameter(Mandatory)]
        [object]$Candidate,

        [string]$OneDriveExe
    )

    $base = $Candidate.SourcePath
    $defaultIconPath = "$base\DefaultIcon"
    $inProcPath = "$base\InProcServer32"
    $instancePath = "$base\Instance"
    $bagPath = "$base\Instance\InitPropertyBag"
    $shellPath = "$base\ShellFolder"

    $root = Get-ItemProperty $base
    $instance = Get-ItemProperty $instancePath -ErrorAction SilentlyContinue
    $bag = Get-ItemProperty $bagPath -ErrorAction SilentlyContinue
    $shell = Get-ItemProperty $shellPath -ErrorAction SilentlyContinue

    $displayName = $Candidate.DisplayName
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        throw "CLSID $($Candidate.Clsid) has no usable display name."
    }

    $desktopName = $Candidate.DesktopName
    if ([string]::IsNullOrWhiteSpace($desktopName)) {
        $desktopName = $displayName
    }

    $defaultIcon = Get-RegistryValue -Path $defaultIconPath
    $defaultIconKind = Get-RegistryValueKind -Path $defaultIconPath

    if ([string]::IsNullOrWhiteSpace([string]$defaultIcon)) {
        if ([string]::IsNullOrWhiteSpace($OneDriveExe)) {
            throw "CLSID $($Candidate.Clsid) has no DefaultIcon and OneDrive.exe could not be located."
        }

        $defaultIcon = "$OneDriveExe,5"
        $defaultIconKind = [Microsoft.Win32.RegistryValueKind]::String
    }

    $inProcServer = Get-RegistryValue -Path $inProcPath
    $inProcKind = Get-RegistryValueKind -Path $inProcPath

    if ([string]::IsNullOrWhiteSpace([string]$inProcServer)) {
        throw "CLSID $($Candidate.Clsid) is missing InProcServer32 in HKCU."
    }

    if ($null -eq $instance -or [string]::IsNullOrWhiteSpace([string]$instance.CLSID)) {
        throw "CLSID $($Candidate.Clsid) is missing Instance\CLSID in HKCU."
    }

    if ($null -eq $shell -or $null -eq $shell.Attributes) {
        throw "CLSID $($Candidate.Clsid) is missing ShellFolder\Attributes in HKCU."
    }

    $targetKnownFolder = $null
    $targetFolderPath = $null

    if ($null -ne $bag) {
        if (-not [string]::IsNullOrWhiteSpace([string]$bag.TargetKnownFolder)) {
            $targetKnownFolder = [string]$bag.TargetKnownFolder
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$bag.TargetFolderPath)) {
            $targetFolderPath = [string]$bag.TargetFolderPath
        }
    }

    [pscustomobject]@{
        Clsid                  = $Candidate.Clsid
        DisplayName            = [string]$displayName
        DesktopName            = [string]$desktopName
        DefaultIcon            = [string]$defaultIcon
        DefaultIconKind        = $defaultIconKind
        InProcServer32         = [string]$inProcServer
        InProcServer32Kind     = $inProcKind
        InstanceClsid          = [string]$instance.CLSID
        TargetKnownFolder      = $targetKnownFolder
        TargetFolderPath       = $targetFolderPath
        InitAttributes         = if ($null -ne $bag -and $null -ne $bag.Attributes) { [UInt32]$bag.Attributes } else { $null }
        ShellFolderAttributes  = [UInt32]$shell.Attributes
        FolderValueFlags       = if ($null -ne $shell.FolderValueFlags) { [UInt32]$shell.FolderValueFlags } else { $null }
        SortOrderIndex         = if ($null -ne $root.SortOrderIndex) { [UInt32]$root.SortOrderIndex } else { $null }
        IsPinned               = if ($null -ne $root.'System.IsPinnedToNameSpaceTree') { [UInt32]$root.'System.IsPinnedToNameSpaceTree' } else { [UInt32]1 }
    }
}

function Repair-Namespace {
    param(
        [Parameter(Mandatory)]
        [object]$Values,

        [Parameter(Mandatory)]
        [string]$BasePath
    )

    Set-RegistryValueNative -KeyPath $BasePath -Type "REG_SZ" -Value $Values.DisplayName

    Set-RegistryValueNative `
        -KeyPath $BasePath `
        -ValueName "System.IsPinnedToNameSpaceTree" `
        -Type "REG_DWORD" `
        -Value (Convert-DwordForRegExe -Value $Values.IsPinned)

    if ($null -ne $Values.SortOrderIndex) {
        Set-RegistryValueNative `
            -KeyPath $BasePath `
            -ValueName "SortOrderIndex" `
            -Type "REG_DWORD" `
            -Value (Convert-DwordForRegExe -Value $Values.SortOrderIndex)
    }

    Set-RegistryValueNative `
        -KeyPath "$BasePath\DefaultIcon" `
        -Type (Convert-RegistryKindToRegExeType -Kind $Values.DefaultIconKind) `
        -Value $Values.DefaultIcon

    Set-RegistryValueNative `
        -KeyPath "$BasePath\InProcServer32" `
        -Type (Convert-RegistryKindToRegExeType -Kind $Values.InProcServer32Kind) `
        -Value $Values.InProcServer32

    Set-RegistryValueNative `
        -KeyPath "$BasePath\Instance" `
        -ValueName "CLSID" `
        -Type "REG_SZ" `
        -Value $Values.InstanceClsid

    if ($null -ne $Values.InitAttributes -or
        -not [string]::IsNullOrWhiteSpace($Values.TargetKnownFolder) -or
        -not [string]::IsNullOrWhiteSpace($Values.TargetFolderPath)) {

        Set-RegistryValueNative `
            -KeyPath "$BasePath\Instance\InitPropertyBag" `
            -ValueName "Attributes" `
            -Type "REG_DWORD" `
            -Value (Convert-DwordForRegExe -Value $Values.InitAttributes)

        if (-not [string]::IsNullOrWhiteSpace($Values.TargetKnownFolder)) {
            Set-RegistryValueNative `
                -KeyPath "$BasePath\Instance\InitPropertyBag" `
                -ValueName "TargetKnownFolder" `
                -Type "REG_SZ" `
                -Value $Values.TargetKnownFolder

            Remove-RegistryValueNative `
                -KeyPath "$BasePath\Instance\InitPropertyBag" `
                -ValueName "TargetFolderPath"
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Values.TargetFolderPath)) {
            Set-RegistryValueNative `
                -KeyPath "$BasePath\Instance\InitPropertyBag" `
                -ValueName "TargetFolderPath" `
                -Type "REG_SZ" `
                -Value $Values.TargetFolderPath

            Remove-RegistryValueNative `
                -KeyPath "$BasePath\Instance\InitPropertyBag" `
                -ValueName "TargetKnownFolder"
        }
    }

    if ($null -ne $Values.FolderValueFlags) {
        Set-RegistryValueNative `
            -KeyPath "$BasePath\ShellFolder" `
            -ValueName "FolderValueFlags" `
            -Type "REG_DWORD" `
            -Value (Convert-DwordForRegExe -Value $Values.FolderValueFlags)
    }

    Set-RegistryValueNative `
        -KeyPath "$BasePath\ShellFolder" `
        -ValueName "Attributes" `
        -Type "REG_DWORD" `
        -Value (Convert-DwordForRegExe -Value $Values.ShellFolderAttributes)
}

function Test-RepairedNamespace {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )

    $required = @(
        $BasePath,
        "$BasePath\DefaultIcon",
        "$BasePath\InProcServer32",
        "$BasePath\Instance",
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
$accountCount = Get-OneDriveAccountCount

[array]$candidates = Get-OneDriveNamespaceCandidates | Where-Object { $null -ne $_ }

if ($candidates.Count -eq 0) {
    throw "No active OneDrive entries found under HKCU Desktop NameSpace."
}

if ($accountCount -gt $candidates.Count) {
    Write-Warning "Detected $accountCount OneDrive account(s), but only $($candidates.Count) Explorer namespace candidate(s)."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $env:USERPROFILE "Desktop\OneDrive-Namespace-Backup-$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

Write-Host "Discovered $($candidates.Count) active OneDrive namespace(s):"
foreach ($candidate in $candidates) {
    Write-Host "  $($candidate.Clsid) : $($candidate.DisplayName)"
}
Write-Host "`nBackup directory: $backupDir`n"

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

        Set-RegistryValueNative `
            -KeyPath $desktopPath `
            -Type "REG_SZ" `
            -Value $values.DesktopName

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

Write-Host "Repair summary:"
$results |
    Format-Table -Property Clsid, DisplayName, NativeHKLM, WowHKLM, DesktopHKLM, Status, Error -AutoSize |
    Out-String |
    Write-Host

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