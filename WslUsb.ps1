#Requires -Version 5.1
<#
.SYNOPSIS
  WSL2 VHDX portable kit: Move / Import / Eject / Backup / Status

.DESCRIPTION
  Single-script workflow to migrate a WSL2 distro VHDX to a USB (or any) directory,
  re-register it after insert, and safely stop before eject. Optional cold backup
  before Move and Eject.

.EXAMPLE
  .\WslUsb.ps1 Move -Distro Ubuntu -Root E:\WSL\Ubuntu -Backup -Confirm
.EXAMPLE
  .\WslUsb.ps1 Import -Root E:\WSL\Ubuntu -Start
.EXAMPLE
  .\WslUsb.ps1 Eject -Root E:\WSL\Ubuntu -Backup
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Move', 'Import', 'Eject', 'Status', 'Backup', 'Help')]
    [string]$Command = 'Help',

    [string]$Distro,
    [string]$Root,
    [string]$UsbLabel,
    [string]$Name,
    [string]$DefaultUser,
    [string]$BackupDir,
    [switch]$Backup,
    [switch]$Start,
    [switch]$Unregister,
    [switch]$SkipHash,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Script:SchemaVersion = 1
$Script:LogPath = $null
$Script:ExitCode = 0

# ---------------------------------------------------------------------------
# Exit codes: 0 ok | 1 generic | 2 prereq | 3 backup | 4 migrate/import | 5 cancel
# ---------------------------------------------------------------------------

function Write-Log {
    param(
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
        [string]$Level = 'INFO',
        [Parameter(Mandatory)][string]$Message
    )
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'OK'    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
    if ($Script:LogPath) {
        try {
            $dir = Split-Path -Parent $Script:LogPath
            if ($dir -and -not (Test-Path -LiteralPath $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Add-Content -LiteralPath $Script:LogPath -Value $line -Encoding UTF8
        } catch { }
    }
}

function Set-LogTarget {
    param([string]$PreferredRoot)
    $stamp = Get-Date -Format 'yyyyMMdd'
    if ($PreferredRoot -and (Test-Path -LiteralPath $PreferredRoot)) {
        $Script:LogPath = Join-Path $PreferredRoot "logs\wsl-usb-$stamp.log"
    } else {
        $tmp = Join-Path $env:TEMP 'WslUsb'
        if (-not (Test-Path -LiteralPath $tmp)) {
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        }
        $Script:LogPath = Join-Path $tmp "wsl-usb-$stamp.log"
    }
}

function Get-WslExe {
    $cmd = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Log ERROR 'wsl.exe not found. Install WSL2 first.'
        $Script:ExitCode = 2
        throw 'WSL_NOT_FOUND'
    }
    return $cmd.Source
}

function Invoke-Wsl {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFail
    )
    $wsl = Get-WslExe
    Write-Log INFO ("wsl " + ($Arguments -join ' '))
    $output = & $wsl @Arguments 2>&1
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    $text = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
    if ($code -ne 0 -and -not $AllowFail) {
        Write-Log ERROR "wsl exited $code`n$text"
        throw "WSL_FAILED:$code"
    }
    [pscustomobject]@{ ExitCode = $code; Output = $text }
}

function Get-WslDistroList {
    # Quiet names are one-per-line; -v for version/state (UTF-16 aware via PowerShell)
    $namesResult = Invoke-Wsl -Arguments @('-l', '-q') -AllowFail
    if ($namesResult.ExitCode -ne 0) {
        Write-Log ERROR 'Failed to list WSL distributions.'
        $Script:ExitCode = 2
        throw 'WSL_LIST_FAILED'
    }
    $names = @()
    foreach ($line in ($namesResult.Output -split "`r?`n")) {
        $n = $line.Trim().TrimStart([char]0xFEFF)
        # Strip UTF-16-ish nulls if present when captured oddly
        $n = ($n -replace "`0", '').Trim()
        if ($n) { $names += $n }
    }

    $verbose = Invoke-Wsl -Arguments @('-l', '-v') -AllowFail
    $map = @{}
    foreach ($name in $names) {
        $map[$name] = [pscustomobject]@{ Name = $name; State = 'Unknown'; Version = 0 }
    }
    if ($verbose.ExitCode -eq 0) {
        foreach ($line in ($verbose.Output -split "`r?`n")) {
            $clean = ($line -replace "`0", '').Trim()
            if (-not $clean -or $clean -match 'NAME') { continue }
            foreach ($name in $names) {
                if ($clean -match [regex]::Escape($name)) {
                    $state = 'Unknown'
                    if ($clean -match 'Running') { $state = 'Running' }
                    elseif ($clean -match 'Stopped') { $state = 'Stopped' }
                    $ver = 0
                    if ($clean -match '\s2\s*$') { $ver = 2 }
                    elseif ($clean -match '\s1\s*$') { $ver = 1 }
                    $map[$name] = [pscustomobject]@{ Name = $name; State = $state; Version = $ver }
                }
            }
        }
    }
    return @($map.Values)
}

function Test-WslDistroExists {
    param([string]$DistroName)
    $list = Get-WslDistroList
    return [bool]($list | Where-Object { $_.Name -eq $DistroName })
}

function Get-WslDistroInfo {
    param([string]$DistroName)
    $list = Get-WslDistroList
    $info = $list | Where-Object { $_.Name -eq $DistroName } | Select-Object -First 1
    if (-not $info) {
        Write-Log ERROR "Distribution '$DistroName' not found."
        $Script:ExitCode = 2
        throw 'DISTRO_NOT_FOUND'
    }
    return $info
}

function Stop-WslClean {
    Write-Log INFO 'Shutting down WSL (wsl --shutdown)...'
    Invoke-Wsl -Arguments @('--shutdown') -AllowFail | Out-Null
    Start-Sleep -Seconds 2
}

function Resolve-UsbRoot {
    param(
        [string]$RootPath,
        [string]$Label,
        [string]$RelativePath = 'WSL\Ubuntu'
    )
    if ($RootPath) {
        return [System.IO.Path]::GetFullPath($RootPath)
    }
    if (-not $Label) {
        Write-Log ERROR 'Specify -Root or -UsbLabel.'
        $Script:ExitCode = 2
        throw 'ROOT_REQUIRED'
    }
    $vol = Get-Volume -ErrorAction SilentlyContinue | Where-Object {
        $_.FileSystemLabel -and ($_.FileSystemLabel.Trim() -eq $Label)
    } | Select-Object -First 1
    if (-not $vol -or -not $vol.DriveLetter) {
        Write-Log ERROR "No volume with label '$Label' found."
        $Script:ExitCode = 2
        throw 'USB_NOT_FOUND'
    }
    $driveRoot = "$($vol.DriveLetter):\"
    return [System.IO.Path]::GetFullPath((Join-Path $driveRoot $RelativePath))
}

function Test-VolumeNtfs {
    param([string]$AnyPath)
    try {
        $full = [System.IO.Path]::GetFullPath($AnyPath)
        $root = [System.IO.Path]::GetPathRoot($full)
        $driveLetter = $root.TrimEnd('\').TrimEnd(':')
        $vol = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if ($vol -and $vol.FileSystem -and $vol.FileSystem -ne 'NTFS') {
            Write-Log WARN "Volume $root is $($vol.FileSystem). NTFS is strongly recommended for VHDX."
            return $false
        }
        return $true
    } catch {
        Write-Log WARN "Could not verify filesystem for '$AnyPath': $_"
        return $true
    }
}

function Test-FreeSpaceBytes {
    param(
        [string]$AnyPath,
        [long]$RequiredBytes
    )
    try {
        $full = [System.IO.Path]::GetFullPath($AnyPath)
        $root = [System.IO.Path]::GetPathRoot($full)
        $drive = Get-PSDrive -Name $root.TrimEnd('\').TrimEnd(':') -ErrorAction SilentlyContinue
        if ($drive -and $drive.Free -lt $RequiredBytes) {
            Write-Log ERROR ("Insufficient free space on {0}: need ~{1:N1} GB, have {2:N1} GB" -f `
                $root, ($RequiredBytes / 1GB), ($drive.Free / 1GB))
            $Script:ExitCode = 2
            return $false
        }
        return $true
    } catch {
        Write-Log WARN "Free-space check skipped: $_"
        return $true
    }
}

function Get-MetaPath {
    param([string]$RootPath)
    Join-Path $RootPath 'meta.json'
}

function Read-Meta {
    param([string]$RootPath)
    $path = Get-MetaPath $RootPath
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Meta {
    param(
        [string]$RootPath,
        [hashtable]$Data
    )
    if (-not (Test-Path -LiteralPath $RootPath)) {
        New-Item -ItemType Directory -Path $RootPath -Force | Out-Null
    }
    $path = Get-MetaPath $RootPath
    $Data['schemaVersion'] = $Script:SchemaVersion
    $json = $Data | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $path -Value $json -Encoding UTF8
    Write-Log OK "Wrote meta: $path"
}

function Get-VhdxPathFromMeta {
    param(
        [string]$RootPath,
        $Meta
    )
    $rel = 'ext4.vhdx'
    if ($Meta -and $Meta.vhdxRelativePath) { $rel = [string]$Meta.vhdxRelativePath }
    $candidate = Join-Path $RootPath $rel
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    # Common layouts after --move / --import
    $hits = @(Get-ChildItem -LiteralPath $RootPath -Filter '*.vhdx' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch 'backup' -and $_.FullName -notmatch '\\backups\\' })
    if ($hits.Count -eq 1) { return $hits[0].FullName }
    if ($hits.Count -gt 1) {
        $ext4 = $hits | Where-Object { $_.Name -eq 'ext4.vhdx' } | Select-Object -First 1
        if ($ext4) { return $ext4.FullName }
    }
    return $null
}

function Get-DefaultUserFromDistro {
    param([string]$DistroName)
    if ($DefaultUser) { return $DefaultUser }
    try {
        $r = Invoke-Wsl -Arguments @(
            '-d', $DistroName, '-e', 'bash', '-lc',
            "grep -E '^default=' /etc/wsl.conf 2>/dev/null | head -1 | cut -d= -f2"
        ) -AllowFail
        $u = ($r.Output -replace "`0", '').Trim()
        if ($u) { return $u }
    } catch { }
    try {
        $r2 = Invoke-Wsl -Arguments @(
            '-d', $DistroName, '-e', 'bash', '-lc',
            'getent passwd | awk -F: ''$3>=1000 && $1!="nobody"{print $1; exit}'''
        ) -AllowFail
        $u2 = ($r2.Output -replace "`0", '').Trim() -split "`n" | Select-Object -First 1
        if ($u2) { return $u2.Trim() }
    } catch { }
    return $null
}

function Restore-DefaultUser {
    param(
        [string]$DistroName,
        [string]$UserName
    )
    if (-not $UserName) {
        Write-Log WARN 'No default user in meta; distro may log in as root. Pass -DefaultUser on Import.'
        return
    }
    Write-Log INFO "Restoring default user '$UserName' for '$DistroName'..."
    $cmd = @"
set -e
if [ -f /etc/wsl.conf ]; then
  if grep -q '^\[user\]' /etc/wsl.conf; then
    if grep -q '^default=' /etc/wsl.conf; then
      sed -i 's/^default=.*/default=$UserName/' /etc/wsl.conf
    else
      sed -i '/^\[user\]/a default=$UserName' /etc/wsl.conf
    fi
  else
    printf '\n[user]\ndefault=$UserName\n' >> /etc/wsl.conf
  fi
else
  printf '[user]\ndefault=$UserName\n' > /etc/wsl.conf
fi
"@
    Invoke-Wsl -Arguments @('-d', $DistroName, '-u', 'root', '-e', 'bash', '-lc', $cmd) -AllowFail | Out-Null
    Invoke-Wsl -Arguments @('--terminate', $DistroName) -AllowFail | Out-Null
    Start-Sleep -Seconds 1
    Write-Log OK "Default user set to '$UserName' (via /etc/wsl.conf)."
}

function Test-ExportVhdSupported {
    $help = Invoke-Wsl -Arguments @('--help') -AllowFail
    $t = $help.Output
    return ($t -match '--vhd' -or $t -match 'format')
}

function Test-ManageMoveSupported {
    $help = Invoke-Wsl -Arguments @('--help') -AllowFail
    return ($help.Output -match '--manage' -or $help.Output -match 'move')
}

function Test-ImportInPlaceSupported {
    $help = Invoke-Wsl -Arguments @('--help') -AllowFail
    return ($help.Output -match 'import-in-place')
}

function Invoke-ExportVhdx {
    param(
        [string]$DistroName,
        [string]$OutFile
    )
    $dir = Split-Path -Parent $OutFile
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Stop-WslClean
    $supported = Test-ExportVhdSupported
    if ($supported) {
        $r = Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile, '--vhd') -AllowFail
        if ($r.ExitCode -ne 0) {
            Write-Log WARN '--export --vhd failed; trying --format vhd...'
            $r = Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile, '--format', 'vhd') -AllowFail
        }
        if ($r.ExitCode -ne 0) {
            Write-Log WARN 'VHD export failed; falling back to .tar export.'
            $tar = [System.IO.Path]::ChangeExtension($OutFile, '.tar')
            Invoke-Wsl -Arguments @('--export', $DistroName, $tar)
            return $tar
        }
    } else {
        $tar = [System.IO.Path]::ChangeExtension($OutFile, '.tar')
        Invoke-Wsl -Arguments @('--export', $DistroName, $tar)
        return $tar
    }
    if (-not (Test-Path -LiteralPath $OutFile) -or ((Get-Item -LiteralPath $OutFile).Length -le 0)) {
        Write-Log ERROR "Backup/export file missing or empty: $OutFile"
        $Script:ExitCode = 3
        throw 'BACKUP_EMPTY'
    }
    if (-not $SkipHash) {
        Write-Log INFO 'Computing SHA256 (use -SkipHash to skip)...'
        try {
            $hash = Get-FileHash -LiteralPath $OutFile -Algorithm SHA256
            Write-Log OK "SHA256: $($hash.Hash)"
            $hashFile = "$OutFile.sha256"
            Set-Content -LiteralPath $hashFile -Value "$($hash.Hash)  $(Split-Path -Leaf $OutFile)" -Encoding ASCII
        } catch {
            Write-Log WARN "Hash skipped: $_"
        }
    }
    return $OutFile
}

function Invoke-SafeBackup {
    param(
        [string]$DistroName,
        [string]$DestinationDir
    )
    if (-not $DistroName) {
        Write-Log ERROR 'Backup requires a distribution name.'
        $Script:ExitCode = 3
        throw 'BACKUP_NO_DISTRO'
    }
    if (-not (Test-WslDistroExists $DistroName)) {
        Write-Log ERROR "Cannot backup missing distro '$DistroName'."
        $Script:ExitCode = 3
        throw 'BACKUP_DISTRO_MISSING'
    }
    if (-not (Test-Path -LiteralPath $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $out = Join-Path $DestinationDir "$DistroName-$stamp.vhdx"
    Write-Log INFO "Safe backup: $DistroName -> $out"
    if (-not $PSCmdlet.ShouldProcess($out, "Backup distribution '$DistroName'")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }
    $path = Invoke-ExportVhdx -DistroName $DistroName -OutFile $out
    Write-Log OK "Backup complete: $path"
    return $path
}

function Invoke-SmokeTest {
    param([string]$DistroName)
    $r = Invoke-Wsl -Arguments @('-d', $DistroName, '-e', 'echo', 'ok') -AllowFail
    if ($r.ExitCode -ne 0 -or ($r.Output -replace "`0", '') -notmatch 'ok') {
        Write-Log ERROR "Smoke test failed for '$DistroName'."
        $Script:ExitCode = 4
        throw 'SMOKE_FAILED'
    }
    Write-Log OK "Smoke test passed for '$DistroName'."
}

function Show-Help {
    @"
WslUsb.ps1 — WSL2 VHDX portable kit (single script)

USAGE
  .\WslUsb.ps1 Move   -Distro <name> -Root <path> [-UsbLabel <label>] [-Backup] [-DefaultUser <user>] [-Confirm]
  .\WslUsb.ps1 Import -Root <path> [-Name <name>] [-DefaultUser <user>] [-Start] [-UsbLabel <label>]
  .\WslUsb.ps1 Eject  -Root <path> [-Backup] [-Unregister] [-UsbLabel <label>]
  .\WslUsb.ps1 Backup -Distro <name> -BackupDir <path>   (or -Root for <Root>\backups)
  .\WslUsb.ps1 Status -Root <path>
  .\WslUsb.ps1 Help

EXIT CODES
  0 success | 1 generic | 2 prereq | 3 backup failed | 4 migrate/import failed | 5 cancelled

NOTES
  - Prefer NTFS USB / USB3 SSD. Always eject via this script before unplugging.
  - Eject does NOT unregister by default (unregister can delete the VHDX).
  - Move prefers: wsl --manage --move ; falls back to export VHDX + import.
"@ | Write-Host
}

# ============================== Commands ===================================

function Invoke-CommandBackup {
    $root = $null
    if ($Root -or $UsbLabel) {
        $root = Resolve-UsbRoot -RootPath $Root -Label $UsbLabel
    }
    $dest = $BackupDir
    if (-not $dest) {
        if ($root) { $dest = Join-Path $root 'backups' }
        else {
            Write-Log ERROR 'Specify -BackupDir or -Root for Backup.'
            $Script:ExitCode = 2
            throw 'BACKUP_DIR_REQUIRED'
        }
    }
    Set-LogTarget $root
    if (-not $Distro) {
        $meta = if ($root) { Read-Meta $root } else { $null }
        if ($meta -and $meta.wslName) { $Distro = [string]$meta.wslName }
    }
    Invoke-SafeBackup -DistroName $Distro -DestinationDir $dest | Out-Null
}

function Invoke-CommandStatus {
    $root = Resolve-UsbRoot -RootPath $Root -Label $UsbLabel
    Set-LogTarget $root
    Write-Log INFO "Root: $root"
    $meta = Read-Meta $root
    if ($meta) {
        Write-Host ($meta | ConvertTo-Json -Depth 6)
    } else {
        Write-Log WARN 'No meta.json found.'
    }
    $vhdx = Get-VhdxPathFromMeta -RootPath $root -Meta $meta
    if ($vhdx) {
        $item = Get-Item -LiteralPath $vhdx
        Write-Log INFO ("VHDX: {0} ({1:N2} GB)" -f $vhdx, ($item.Length / 1GB))
    } else {
        Write-Log WARN 'No VHDX found under Root.'
    }
    $name = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } else { $null }
    if ($name -and (Test-WslDistroExists $name)) {
        $info = Get-WslDistroInfo $name
        Write-Log INFO ("Registered: {0}  State={1}  Version={2}" -f $info.Name, $info.State, $info.Version)
    } elseif ($name) {
        Write-Log WARN "Not registered on this machine: $name"
    }
    Test-VolumeNtfs $root | Out-Null
}

function Invoke-CommandMove {
    if (-not $Distro) {
        Write-Log ERROR 'Move requires -Distro.'
        $Script:ExitCode = 2
        throw 'DISTRO_REQUIRED'
    }
    $root = Resolve-UsbRoot -RootPath $Root -Label $UsbLabel
    Set-LogTarget $root
    $info = Get-WslDistroInfo $Distro
    if ($info.Version -eq 1) {
        Write-Log ERROR 'WSL1 is not supported for VHDX move. Convert to WSL2 first.'
        $Script:ExitCode = 2
        throw 'WSL1_UNSUPPORTED'
    }

    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }
    Test-VolumeNtfs $root | Out-Null

    $targetName = if ($Name) { $Name } else { $Distro }
    $user = Get-DefaultUserFromDistro -DistroName $Distro

    $bdir = if ($BackupDir) { $BackupDir } else { Join-Path $root 'backups' }
    if ($Backup) {
        try {
            Invoke-SafeBackup -DistroName $Distro -DestinationDir $bdir | Out-Null
        } catch {
            if ($Script:ExitCode -eq 0) { $Script:ExitCode = 3 }
            throw
        }
    }

    if (-not $PSCmdlet.ShouldProcess($root, "Move '$Distro' VHDX to '$root'")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }

    $moved = $false
    if (Test-ManageMoveSupported) {
        Write-Log INFO 'Trying wsl --manage --move ...'
        Stop-WslClean
        $r = Invoke-Wsl -Arguments @('--manage', $Distro, '--move', $root) -AllowFail
        if ($r.ExitCode -eq 0) {
            $moved = $true
            $targetName = $Distro
            Write-Log OK 'Move completed via --manage --move.'
        } else {
            Write-Log WARN '--manage --move failed; falling back to export/import.'
        }
    }

    if (-not $moved) {
        $migrateFile = Join-Path $root '_migrate.vhdx'
        Write-Log INFO 'Fallback: export VHDX then import into Root...'
        $exported = Invoke-ExportVhdx -DistroName $Distro -OutFile $migrateFile
        $isTar = $exported -like '*.tar'

        if ($targetName -eq $Distro -and (Test-WslDistroExists $Distro)) {
            # Import under temporary name, verify, then replace
            $tempName = "$Distro-usb-tmp"
            if (Test-WslDistroExists $tempName) {
                Write-Log ERROR "Temporary name '$tempName' already exists. Remove it or pass -Name."
                $Script:ExitCode = 4
                throw 'TEMP_EXISTS'
            }
            if ($isTar) {
                Invoke-Wsl -Arguments @('--import', $tempName, $root, $exported, '--version', '2')
            } else {
                Invoke-Wsl -Arguments @('--import', $tempName, $root, $exported, '--vhd', '--version', '2')
            }
            Restore-DefaultUser -DistroName $tempName -UserName $user
            Invoke-SmokeTest -DistroName $tempName

            if (-not $Force -and -not $PSCmdlet.ShouldProcess($Distro, "Unregister original '$Distro' after successful migrate")) {
                Write-Log WARN "Left both '$Distro' and '$tempName'. Re-run with -Force to unregister the original, or unregister manually."
                $targetName = $tempName
            } else {
                Stop-WslClean
                Invoke-Wsl -Arguments @('--unregister', $Distro)
                # Re-register under original name from the vhdx now under root
                $vhdxNow = Get-VhdxPathFromMeta -RootPath $root -Meta $null
                if (-not $vhdxNow) {
                    Write-Log ERROR 'Could not locate VHDX after import.'
                    $Script:ExitCode = 4
                    throw 'VHDX_MISSING'
                }
                # Unregister temp (may delete vhdx!) — avoid: instead keep temp name OR import-in-place after copy
                # Safer: keep using tempName as wslName, document rename; OR unregister temp only if we import-in-place from copy
                Write-Log WARN "Original unregistered. Keeping registered name '$tempName' (VHDX under Root). Use Import -Name to re-bind if needed."
                $targetName = $tempName
            }
        } else {
            if (Test-WslDistroExists $targetName) {
                Write-Log ERROR "Target name '$targetName' already exists. Choose -Name or unregister it."
                $Script:ExitCode = 4
                throw 'NAME_EXISTS'
            }
            if ($isTar) {
                Invoke-Wsl -Arguments @('--import', $targetName, $root, $exported, '--version', '2')
            } else {
                Invoke-Wsl -Arguments @('--import', $targetName, $root, $exported, '--vhd', '--version', '2')
            }
            Restore-DefaultUser -DistroName $targetName -UserName $user
            Invoke-SmokeTest -DistroName $targetName
            if ($Force -and $Distro -ne $targetName -and (Test-WslDistroExists $Distro)) {
                if ($PSCmdlet.ShouldProcess($Distro, "Unregister source '$Distro'")) {
                    Stop-WslClean
                    Invoke-Wsl -Arguments @('--unregister', $Distro)
                }
            }
        }

        if (Test-Path -LiteralPath $migrateFile) {
            Remove-Item -LiteralPath $migrateFile -Force -ErrorAction SilentlyContinue
        }
    } else {
        if ($user) { Restore-DefaultUser -DistroName $targetName -UserName $user }
        Invoke-SmokeTest -DistroName $targetName
    }

    $vhdxPath = Get-VhdxPathFromMeta -RootPath $root -Meta $null
    $rel = if ($vhdxPath) {
        $vhdxPath.Substring($root.Length).TrimStart('\', '/')
    } else { 'ext4.vhdx' }

    Write-Meta -RootPath $root -Data @{
        distroName         = $Distro
        wslName            = $targetName
        wslVersion         = 2
        defaultUser        = $user
        vhdxRelativePath   = $rel
        createdAt          = (Get-Date).ToUniversalTime().ToString('o')
        lastMovedAt        = (Get-Date).ToUniversalTime().ToString('o')
        lastHost           = $env:COMPUTERNAME
        lastDriveLetter    = ([System.IO.Path]::GetPathRoot($root)).TrimEnd('\')
    }
    Write-Log OK "Move finished. Root=$root Name=$targetName"
}

function Invoke-CommandImport {
    $root = Resolve-UsbRoot -RootPath $Root -Label $UsbLabel
    Set-LogTarget $root
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Log ERROR "Root not found: $root"
        $Script:ExitCode = 2
        throw 'ROOT_MISSING'
    }
    $meta = Read-Meta $root
    $targetName = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } else { 'UbuntuUSB' }
    $user = if ($DefaultUser) { $DefaultUser } elseif ($meta -and $meta.defaultUser) { [string]$meta.defaultUser } else { $null }

    $vhdx = Get-VhdxPathFromMeta -RootPath $root -Meta $meta
    if (-not $vhdx) {
        Write-Log ERROR "No VHDX under '$root'. Run Move first."
        $Script:ExitCode = 4
        throw 'VHDX_MISSING'
    }

    Test-VolumeNtfs $root | Out-Null

    if (Test-WslDistroExists $targetName) {
        Write-Log OK "Already registered: $targetName (idempotent Import)."
        if ($user) { Restore-DefaultUser -DistroName $targetName -UserName $user }
    } else {
        if (-not $PSCmdlet.ShouldProcess($vhdx, "Import-in-place as '$targetName'")) {
            $Script:ExitCode = 5
            throw 'USER_CANCELLED'
        }
        if (Test-ImportInPlaceSupported) {
            Write-Log INFO 'Registering via wsl --import-in-place ...'
            $r = Invoke-Wsl -Arguments @('--import-in-place', $targetName, $vhdx) -AllowFail
            if ($r.ExitCode -ne 0) {
                Write-Log WARN 'import-in-place failed; trying wsl --import --vhd ...'
                Invoke-Wsl -Arguments @('--import', $targetName, $root, $vhdx, '--vhd', '--version', '2')
            }
        } else {
            Invoke-Wsl -Arguments @('--import', $targetName, $root, $vhdx, '--vhd', '--version', '2')
        }
        Restore-DefaultUser -DistroName $targetName -UserName $user
        Invoke-SmokeTest -DistroName $targetName
    }

    $rel = $vhdx.Substring($root.Length).TrimStart('\', '/')
    $data = @{
        distroName       = if ($meta -and $meta.distroName) { $meta.distroName } else { $targetName }
        wslName          = $targetName
        wslVersion       = 2
        defaultUser      = $user
        vhdxRelativePath = $rel
        lastImportedAt   = (Get-Date).ToUniversalTime().ToString('o')
        lastHost         = $env:COMPUTERNAME
        lastDriveLetter  = ([System.IO.Path]::GetPathRoot($root)).TrimEnd('\')
    }
    if ($meta -and $meta.createdAt) { $data['createdAt'] = $meta.createdAt }
    if ($meta -and $meta.lastMovedAt) { $data['lastMovedAt'] = $meta.lastMovedAt }
    Write-Meta -RootPath $root -Data $data

    Write-Log OK "Import ready: wsl -d $targetName"
    if ($Start) {
        Write-Log INFO "Starting $targetName ..."
        $wsl = Get-WslExe
        & $wsl -d $targetName
    }
}

function Invoke-CommandEject {
    $root = Resolve-UsbRoot -RootPath $Root -Label $UsbLabel
    Set-LogTarget $root
    $meta = Read-Meta $root
    $targetName = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } elseif ($Distro) { $Distro } else { $null }

    if (-not $targetName) {
        Write-Log ERROR 'Cannot resolve distro name. Pass -Name or ensure meta.json exists.'
        $Script:ExitCode = 2
        throw 'NAME_REQUIRED'
    }

    $bdir = if ($BackupDir) { $BackupDir } else { Join-Path $root 'backups' }
    if ($Backup) {
        if (-not (Test-WslDistroExists $targetName)) {
            Write-Log ERROR "Cannot backup: '$targetName' is not registered."
            $Script:ExitCode = 3
            throw 'BACKUP_DISTRO_MISSING'
        }
        try {
            Invoke-SafeBackup -DistroName $targetName -DestinationDir $bdir | Out-Null
        } catch {
            if ($Script:ExitCode -eq 0) { $Script:ExitCode = 3 }
            throw
        }
    }

    if (-not $PSCmdlet.ShouldProcess($targetName, "Terminate/shutdown before eject")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }

    if (Test-WslDistroExists $targetName) {
        Write-Log INFO "Terminating '$targetName'..."
        Invoke-Wsl -Arguments @('--terminate', $targetName) -AllowFail | Out-Null
    }
    Stop-WslClean

    if ($Unregister) {
        Write-Log WARN 'Unregister can DELETE the VHDX file associated with the distro.'
        if ($PSCmdlet.ShouldProcess($targetName, 'Unregister distro (DANGEROUS for USB-resident VHDX)')) {
            # Prefer not to delete USB vhdx: warn heavily; only proceed with -Force
            if (-not $Force) {
                Write-Log ERROR 'Refusing unregister without -Force. Eject completed stop/sync only.'
            } else {
                Write-Log WARN "Unregistering '$targetName' with -Force..."
                Invoke-Wsl -Arguments @('--unregister', $targetName)
            }
        }
    }

    if ($meta) {
        $data = @{}
        foreach ($p in $meta.PSObject.Properties) { $data[$p.Name] = $p.Value }
        $data['lastEjectedAt'] = (Get-Date).ToUniversalTime().ToString('o')
        $data['lastHost'] = $env:COMPUTERNAME
        Write-Meta -RootPath $root -Data $data
    }

    Write-Log OK 'WSL stopped. You can safely Eject the USB from Explorer.'
    Write-Host ''
    Write-Host '  Next: tray/Explorer -> Eject removable disk' -ForegroundColor Cyan
    Write-Host ''
}

# ============================== Main =======================================

try {
    Get-WslExe | Out-Null
    switch ($Command) {
        'Help'   { Show-Help }
        'Backup' { Invoke-CommandBackup }
        'Status' { Invoke-CommandStatus }
        'Move'   { Invoke-CommandMove }
        'Import' { Invoke-CommandImport }
        'Eject'  { Invoke-CommandEject }
    }
} catch {
    if ($Script:ExitCode -eq 0) { $Script:ExitCode = 1 }
    $msg = $_.Exception.Message
    if ($msg -notin @('USER_CANCELLED', 'WSL_NOT_FOUND', 'BACKUP_EMPTY', 'SMOKE_FAILED', 'DISTRO_NOT_FOUND', 'ROOT_REQUIRED', 'USB_NOT_FOUND', 'WSL_LIST_FAILED', 'WSL1_UNSUPPORTED', 'BACKUP_NO_DISTRO', 'BACKUP_DISTRO_MISSING', 'BACKUP_DIR_REQUIRED', 'TEMP_EXISTS', 'VHDX_MISSING', 'NAME_EXISTS', 'ROOT_MISSING', 'NAME_REQUIRED')) {
        Write-Log ERROR $msg
    }
    if ($msg -eq 'USER_CANCELLED') {
        Write-Log WARN 'Cancelled by user.'
    }
}

exit $Script:ExitCode
