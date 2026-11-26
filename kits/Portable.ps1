#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Portable 模块：Move / Import / Eject / Backup / Status

.DESCRIPTION
  将发行版 export 到可移动介质，再 wsl --import 到本机路径日常使用；弹出前注销本机副本（介质保留导出物）。
  RFC-ARCH-001。推荐：.\WslKit.ps1 Portable <Command> ...

.EXAMPLE
  .\WslKit.ps1 Portable Move -Distro Ubuntu -Root E:\WSLkit -Backup -Confirm
.EXAMPLE
  .\WslKit.ps1 Portable Import -Root E:\WSLkit -Start
.EXAMPLE
  .\WslKit.ps1 Portable Eject -Root E:\WSLkit -Confirm
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Move', 'Migrate', 'Import', 'Eject', 'Status', 'Backup', 'Help')]
    [string]$Command = 'Help',

    [string]$Distro,
    [string]$Root,
    [Alias('UsbLabel')]
    [string]$MediaLabel,
    [string]$Name,
    [string]$DefaultUser,
    [string]$HostRoot,
    [string]$BackupDir,
    [switch]$Backup,
    [switch]$Start,
    [switch]$SkipHash,
    [switch]$SkipReExport,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Script:SchemaVersion = 1
$Script:Lifecycle = 'export-import'
$Script:LogPath = $null
$Script:ExitCode = 0

if ($Command -eq 'Migrate') { $Command = 'Move' }

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
        $Script:LogPath = Join-Path $PreferredRoot "logs\wslkit-portable-$stamp.log"
    } else {
        $tmp = Join-Path $env:TEMP 'WslKit'
        if (-not (Test-Path -LiteralPath $tmp)) {
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        }
        $Script:LogPath = Join-Path $tmp "wslkit-portable-$stamp.log"
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

function Get-WslDistroNames {
    $r = Invoke-Wsl -Arguments @('-l', '-q') -AllowFail
    if ($r.ExitCode -ne 0) {
        Write-Log ERROR 'Failed to list WSL distributions.'
        $Script:ExitCode = 2
        throw 'WSL_LIST_FAILED'
    }
    $names = @()
    foreach ($line in ($r.Output -split "`r?`n")) {
        $n = ($line -replace "`0", '').Trim().TrimStart([char]0xFEFF)
        if ($n) { $names += $n }
    }
    return $names
}

function Test-WslDistroExists {
    param([string]$DistroName)
    return [bool]((Get-WslDistroNames) | Where-Object { $_ -eq $DistroName })
}

function Get-WslDistroVersion {
    param([string]$DistroName)
    $verbose = Invoke-Wsl -Arguments @('-l', '-v') -AllowFail
    if ($verbose.ExitCode -ne 0) { return 0 }
    foreach ($line in ($verbose.Output -split "`r?`n")) {
        $clean = ($line -replace "`0", '').Trim()
        if ($clean -match [regex]::Escape($DistroName)) {
            if ($clean -match '\s2\s*$') { return 2 }
            if ($clean -match '\s1\s*$') { return 1 }
        }
    }
    return 0
}

function Stop-WslClean {
    Write-Log INFO 'Shutting down WSL (wsl --shutdown)...'
    Invoke-Wsl -Arguments @('--shutdown') -AllowFail | Out-Null
    Start-Sleep -Seconds 2
}

function Resolve-MediaRoot {
    param(
        [string]$RootPath,
        [string]$Label,
        [string]$RelativePath = 'WSLkit'
    )
    if ($RootPath) {
        return [System.IO.Path]::GetFullPath($RootPath)
    }
    if (-not $Label) {
        Write-Log ERROR '请指定 -Root 或 -MediaLabel（兼容旧名 -UsbLabel）。'
        $Script:ExitCode = 2
        throw 'ROOT_REQUIRED'
    }
    $vol = Get-Volume -ErrorAction SilentlyContinue | Where-Object {
        $_.FileSystemLabel -and ($_.FileSystemLabel.Trim() -eq $Label)
    } | Select-Object -First 1
    if (-not $vol -or -not $vol.DriveLetter) {
        Write-Log ERROR "未找到卷标为 '$Label' 的磁盘。"
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
            Write-Log WARN "Volume $root is $($vol.FileSystem). NTFS is strongly recommended."
            return $false
        }
        return $true
    } catch {
        Write-Log WARN "Could not verify filesystem for '$AnyPath': $_"
        return $true
    }
}

function Get-MetaPath { param([string]$RootPath) Join-Path $RootPath 'meta.json' }

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
    $Data['lifecycle'] = $Script:Lifecycle
    $json = $Data | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $path -Value $json -Encoding UTF8
    Write-Log OK "Wrote meta: $path"
}

function Convert-MetaToHashtable {
    param($Meta)
    $data = @{}
    if (-not $Meta) { return $data }
    foreach ($p in $Meta.PSObject.Properties) {
        $data[$p.Name] = $p.Value
    }
    return $data
}

function Get-ArtifactPath {
    param(
        [string]$RootPath,
        $Meta,
        [string]$WslName
    )
    if ($Meta -and $Meta.artifactRelativePath) {
        $p = Join-Path $RootPath ([string]$Meta.artifactRelativePath)
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $distDir = Join-Path $RootPath 'distros'
    foreach ($ext in @('.vhdx', '.vhd', '.tar')) {
        $candidate = Join-Path $distDir ($WslName + $ext)
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    if (Test-Path -LiteralPath $distDir) {
        $hits = @(Get-ChildItem -LiteralPath $distDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '^\.(vhdx|vhd|tar)$' })
        if ($hits.Count -eq 1) { return $hits[0].FullName }
    }
    return $null
}

function Get-DefaultHostInstallPath {
    param([string]$WslName)
    if ($HostRoot) {
        return [System.IO.Path]::GetFullPath((Join-Path $HostRoot $WslName))
    }
    return [System.IO.Path]::GetFullPath((Join-Path $env:USERPROFILE "WSLkit\$WslName"))
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
        # here-string avoids PS 5.1 quote/`&&` parsing pitfalls around the awk program
        $probe = @'
getent passwd | awk -F: '$3>=1000 && $1!="nobody"{print $1; exit}'
'@
        $r2 = Invoke-Wsl -Arguments @(
            '-d', $DistroName, '-e', 'bash', '-lc', $probe
        ) -AllowFail
        $u2 = (($r2.Output -replace "`0", '').Trim() -split "`n" | Select-Object -First 1)
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
        Write-Log WARN 'No default user; distro may log in as root. Pass -DefaultUser.'
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
    Write-Log OK "Default user set to '$UserName'."
}

function Test-ExportVhdSupported {
    $help = Invoke-Wsl -Arguments @('--help') -AllowFail
    return ($help.Output -match '--vhd' -or $help.Output -match 'format')
}

function Invoke-ExportArtifact {
    param(
        [string]$DistroName,
        [string]$OutFile
    )
    $dir = Split-Path -Parent $OutFile
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    if (Test-Path -LiteralPath $OutFile) {
        Remove-Item -LiteralPath $OutFile -Force
    }
    Stop-WslClean
    $format = 'vhdx'
    if (Test-ExportVhdSupported) {
        $r = Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile, '--vhd') -AllowFail
        if ($r.ExitCode -ne 0) {
            Write-Log WARN '--export --vhd failed; trying --format vhd...'
            $r = Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile, '--format', 'vhd') -AllowFail
        }
        if ($r.ExitCode -ne 0) {
            Write-Log WARN 'VHD export failed; falling back to .tar.'
            $OutFile = [System.IO.Path]::ChangeExtension($OutFile, '.tar')
            if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
            Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile)
            $format = 'tar'
        }
    } else {
        $OutFile = [System.IO.Path]::ChangeExtension($OutFile, '.tar')
        if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
        Invoke-Wsl -Arguments @('--export', $DistroName, $OutFile)
        $format = 'tar'
    }
    if (-not (Test-Path -LiteralPath $OutFile) -or ((Get-Item -LiteralPath $OutFile).Length -le 0)) {
        Write-Log ERROR "Export missing or empty: $OutFile"
        $Script:ExitCode = 3
        throw 'EXPORT_EMPTY'
    }
    if (-not $SkipHash) {
        Write-Log INFO 'Computing SHA256 (use -SkipHash to skip)...'
        try {
            $hash = Get-FileHash -LiteralPath $OutFile -Algorithm SHA256
            Write-Log OK "SHA256: $($hash.Hash)"
            Set-Content -LiteralPath "$OutFile.sha256" -Value "$($hash.Hash)  $(Split-Path -Leaf $OutFile)" -Encoding ASCII
        } catch {
            Write-Log WARN "Hash skipped: $_"
        }
    }
    [pscustomobject]@{ Path = $OutFile; Format = $format }
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
    $result = Invoke-ExportArtifact -DistroName $DistroName -OutFile $out
    Write-Log OK "Backup complete: $($result.Path)"
    return $result.Path
}

function Invoke-ImportHostLocal {
    param(
        [string]$WslName,
        [string]$HostInstallPath,
        [string]$ArtifactPath,
        [string]$Format
    )
    if (-not (Test-Path -LiteralPath $HostInstallPath)) {
        New-Item -ItemType Directory -Path $HostInstallPath -Force | Out-Null
    }
    Stop-WslClean
    $isVhd = ($Format -match 'vhd') -or ($ArtifactPath -match '\.vhd')
    if ($isVhd) {
        $r = Invoke-Wsl -Arguments @('--import', $WslName, $HostInstallPath, $ArtifactPath, '--vhd', '--version', '2') -AllowFail
        if ($r.ExitCode -ne 0) {
            Write-Log WARN 'import --vhd failed; retrying without --vhd flag spelling...'
            Invoke-Wsl -Arguments @('--import', $WslName, $HostInstallPath, $ArtifactPath, '--version', '2')
        }
    } else {
        Invoke-Wsl -Arguments @('--import', $WslName, $HostInstallPath, $ArtifactPath, '--version', '2')
    }
}

function Invoke-SmokeTest {
    param(
        [string]$DistroName,
        [string]$UserName
    )
    $args = @('-d', $DistroName)
    if ($UserName) { $args += @('-u', $UserName) }
    $args += @('-e', 'echo', 'ok')
    $r = Invoke-Wsl -Arguments $args -AllowFail
    if ($r.ExitCode -ne 0 -or ($r.Output -replace "`0", '') -notmatch 'ok') {
        Write-Log ERROR "Smoke test failed for '$DistroName'."
        $Script:ExitCode = 4
        throw 'SMOKE_FAILED'
    }
    Write-Log OK "Smoke test passed for '$DistroName'."
}

function Show-Help {
    @"
Portable.ps1 — WSLkit 便携模块（export 到介质 / import 到本机）

用法
  .\WslKit.ps1 Portable Move    -Distro <名称> -Root <介质目录> [-Backup] [-Name <名称>] [-DefaultUser <用户>] [-Confirm]
  .\WslKit.ps1 Portable Import  -Root <介质目录> [-Name <名称>] [-HostRoot <路径>] [-DefaultUser <用户>] [-Start] [-Confirm]
  .\WslKit.ps1 Portable Eject   -Root <介质目录> [-Name <名称>] [-Backup] [-SkipReExport] [-Confirm]
  .\WslKit.ps1 Portable Backup  -Distro <名称> [-Root <介质目录>] [-BackupDir <路径>]
  .\WslKit.ps1 Portable Status  -Root <介质目录>
  .\WslKit.ps1 Portable Help

当前模式（export / import）
  Move/Migrate  wsl --export 到介质，然后注销【源机】发行版
  Import        wsl --import 到 %USERPROFILE%\WSLkit\<名称>（本机副本）
  Eject         默认将本机状态 re-export 回介质（可用 -SkipReExport 跳过），注销【本机】副本后弹出

远期可选（未实现）：介质驻留 VHDX + wsl --import-in-place

退出码
  0 成功 | 1 通用错误 | 2 前置失败 | 3 备份/导出失败 | 4 迁移/导入失败 | 5 用户取消

详见 docs/portable.md 与 RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md
"@ | Write-Host
}

function Invoke-CommandBackup {
    $root = $null
    if ($Root -or $MediaLabel) {
        $root = Resolve-MediaRoot -RootPath $Root -Label $MediaLabel
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
    $root = Resolve-MediaRoot -RootPath $Root -Label $MediaLabel
    Set-LogTarget $root
    Write-Log INFO "Media Root: $root"
    $meta = Read-Meta $root
    if ($meta) {
        Write-Host ($meta | ConvertTo-Json -Depth 8)
    } else {
        Write-Log WARN 'No meta.json found.'
    }
    $wslName = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } else { $null }
    $artifact = if ($wslName) { Get-ArtifactPath -RootPath $root -Meta $meta -WslName $wslName } else { $null }
    if ($artifact) {
        $item = Get-Item -LiteralPath $artifact
        Write-Log INFO ("Artifact: {0} ({1:N2} GB)" -f $artifact, ($item.Length / 1GB))
    } else {
        Write-Log WARN 'No export artifact under Root\distros.'
    }
    if ($wslName -and (Test-WslDistroExists $wslName)) {
        Write-Log INFO "Registered on this host: $wslName"
        if ($meta -and $meta.hostInstallPath) {
            Write-Log INFO "meta.hostInstallPath: $($meta.hostInstallPath)"
        }
    } elseif ($wslName) {
        Write-Log WARN "Not registered on this host: $wslName"
    }
    Test-VolumeNtfs $root | Out-Null
}

function Invoke-CommandMove {
    if (-not $Distro) {
        Write-Log ERROR 'Move requires -Distro.'
        $Script:ExitCode = 2
        throw 'DISTRO_REQUIRED'
    }
    if (-not (Test-WslDistroExists $Distro)) {
        Write-Log ERROR "Distribution '$Distro' not found."
        $Script:ExitCode = 2
        throw 'DISTRO_NOT_FOUND'
    }
    $ver = Get-WslDistroVersion $Distro
    if ($ver -eq 1) {
        Write-Log ERROR 'WSL1 is not supported.'
        $Script:ExitCode = 2
        throw 'WSL1_UNSUPPORTED'
    }

    $root = Resolve-MediaRoot -RootPath $Root -Label $MediaLabel
    Set-LogTarget $root
    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }
    Test-VolumeNtfs $root | Out-Null

    $wslName = if ($Name) { $Name } else { $Distro }
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

    $distDir = Join-Path $root 'distros'
    $artifactOut = Join-Path $distDir "$wslName.vhdx"
    if (-not $PSCmdlet.ShouldProcess($artifactOut, "Export '$Distro' to media and unregister source")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }

    $exported = Invoke-ExportArtifact -DistroName $Distro -OutFile $artifactOut
    $rel = $exported.Path.Substring($root.Length).TrimStart('\', '/')

    Write-Meta -RootPath $root -Data @{
        distroName           = $Distro
        wslName              = $wslName
        wslVersion           = 2
        defaultUser          = $user
        artifactRelativePath = $rel
        artifactFormat       = $exported.Format
        createdAt            = (Get-Date).ToUniversalTime().ToString('o')
        lastMovedAt          = (Get-Date).ToUniversalTime().ToString('o')
        lastHost             = $env:COMPUTERNAME
        lastDriveLetter      = ([System.IO.Path]::GetPathRoot($root)).TrimEnd('\')
        hostInstallPath      = $null
    }

    Write-Log INFO "Unregistering source distro '$Distro' (source InstallLocation only)..."
    if (-not $PSCmdlet.ShouldProcess($Distro, "Unregister source '$Distro' after successful export")) {
        Write-Log WARN "Export OK but source not unregistered (cancelled). Artifact: $($exported.Path)"
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }
    Stop-WslClean
    Invoke-Wsl -Arguments @('--unregister', $Distro)
    Write-Log OK "Move finished. Media artifact=$($exported.Path)  Name=$wslName"
    Write-Log INFO '下一步：在另一台电脑执行 Import -Root <介质目录>，拔出前再 Eject。'
}

function Invoke-CommandImport {
    $root = Resolve-MediaRoot -RootPath $Root -Label $MediaLabel
    Set-LogTarget $root
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Log ERROR "Root not found: $root"
        $Script:ExitCode = 2
        throw 'ROOT_MISSING'
    }
    $meta = Read-Meta $root
    if ($meta -and $meta.lifecycle -and [string]$meta.lifecycle -ne $Script:Lifecycle) {
        Write-Log WARN "meta.lifecycle=$($meta.lifecycle); expected $Script:Lifecycle (export-import)."
    }

    $wslName = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } else { 'Ubuntu' }
    $user = if ($DefaultUser) { $DefaultUser } elseif ($meta -and $meta.defaultUser) { [string]$meta.defaultUser } else { $null }
    $artifact = Get-ArtifactPath -RootPath $root -Meta $meta -WslName $wslName
    if (-not $artifact) {
        Write-Log ERROR "No export artifact under '$root'. Run Move first."
        $Script:ExitCode = 4
        throw 'ARTIFACT_MISSING'
    }
    $format = if ($meta -and $meta.artifactFormat) { [string]$meta.artifactFormat } elseif ($artifact -match '\.tar$') { 'tar' } else { 'vhdx' }
    $hostPath = Get-DefaultHostInstallPath -WslName $wslName

    Test-VolumeNtfs $root | Out-Null

    if (Test-WslDistroExists $wslName) {
        if (-not $Force) {
            Write-Log ERROR "Distro '$wslName' already registered. Eject first or pass -Force to unregister host copy."
            $Script:ExitCode = 4
            throw 'NAME_EXISTS'
        }
        if (-not $PSCmdlet.ShouldProcess($wslName, "Force unregister existing '$wslName' before import")) {
            $Script:ExitCode = 5
            throw 'USER_CANCELLED'
        }
        Stop-WslClean
        Invoke-Wsl -Arguments @('--unregister', $wslName)
    }

    if (-not $PSCmdlet.ShouldProcess($hostPath, "Import '$wslName' from media to host-local path")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }

    # Safety: export/import keeps InstallLocation off the media Root
    $artFull = [System.IO.Path]::GetFullPath($artifact)
    $hostFull = [System.IO.Path]::GetFullPath($hostPath)
    if ($hostFull.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Log ERROR 'Host install path must not be under media Root (export/import copies to host disk).'
        $Script:ExitCode = 4
        throw 'HOST_PATH_ON_MEDIA'
    }

    Invoke-ImportHostLocal -WslName $wslName -HostInstallPath $hostPath -ArtifactPath $artFull -Format $format
    Restore-DefaultUser -DistroName $wslName -UserName $user
    Invoke-SmokeTest -DistroName $wslName -UserName $user

    $data = Convert-MetaToHashtable $meta
    $data['wslName'] = $wslName
    $data['defaultUser'] = $user
    $data['artifactRelativePath'] = $artFull.Substring($root.Length).TrimStart('\', '/')
    $data['artifactFormat'] = $format
    $data['hostInstallPath'] = $hostPath
    $data['lastImportedAt'] = (Get-Date).ToUniversalTime().ToString('o')
    $data['lastHost'] = $env:COMPUTERNAME
    $data['lastDriveLetter'] = ([System.IO.Path]::GetPathRoot($root)).TrimEnd('\')
    if (-not $data.ContainsKey('distroName') -or -not $data['distroName']) { $data['distroName'] = $wslName }
    Write-Meta -RootPath $root -Data $data

    Write-Log OK "Import ready: wsl -d $wslName$(if ($user) { " -u $user" })"
    Write-Log INFO "Host InstallLocation: $hostPath"
    if ($Start) {
        $wsl = Get-WslExe
        if ($user) { & $wsl -d $wslName -u $user } else { & $wsl -d $wslName }
    }
}

function Invoke-CommandEject {
    $root = Resolve-MediaRoot -RootPath $Root -Label $MediaLabel
    Set-LogTarget $root
    $meta = Read-Meta $root
    $wslName = if ($Name) { $Name } elseif ($meta -and $meta.wslName) { [string]$meta.wslName } elseif ($Distro) { $Distro } else { $null }
    if (-not $wslName) {
        Write-Log ERROR 'Cannot resolve distro name. Pass -Name or ensure meta.json exists.'
        $Script:ExitCode = 2
        throw 'NAME_REQUIRED'
    }

    $bdir = if ($BackupDir) { $BackupDir } else { Join-Path $root 'backups' }
    if ($Backup) {
        if (-not (Test-WslDistroExists $wslName)) {
            Write-Log ERROR "Cannot backup: '$wslName' is not registered."
            $Script:ExitCode = 3
            throw 'BACKUP_DISTRO_MISSING'
        }
        try {
            Invoke-SafeBackup -DistroName $wslName -DestinationDir $bdir | Out-Null
        } catch {
            if ($Script:ExitCode -eq 0) { $Script:ExitCode = 3 }
            throw
        }
    }

    if (-not (Test-WslDistroExists $wslName)) {
        Write-Log WARN "'$wslName' is not registered; nothing to unregister. You can eject the media."
        return
    }

    # Refuse unregister if hostInstallPath is missing and we cannot prove host-local — still unregister by name
    # but warn if meta says artifact path equals something under root that might be in-place (Phase 2 not shipped)
    if ($meta -and $meta.hostInstallPath) {
        $hip = [string]$meta.hostInstallPath
        if ($hip -and $hip.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Log ERROR 'meta.hostInstallPath is under media Root. Refusing Eject unregister (would risk media VHDX).'
            $Script:ExitCode = 4
            throw 'UNSAFE_UNREGISTER'
        }
    }

    if (-not $SkipReExport) {
        $artifactTarget = Get-ArtifactPath -RootPath $root -Meta $meta -WslName $wslName
        if (-not $artifactTarget) {
            $artifactTarget = Join-Path (Join-Path $root 'distros') "$wslName.vhdx"
        }
        if (-not $PSCmdlet.ShouldProcess($artifactTarget, "Re-export host '$wslName' to media before unregister")) {
            $Script:ExitCode = 5
            throw 'USER_CANCELLED'
        }
        $exported = Invoke-ExportArtifact -DistroName $wslName -OutFile $artifactTarget
        $data = Convert-MetaToHashtable $meta
        $data['wslName'] = $wslName
        $data['artifactRelativePath'] = $exported.Path.Substring($root.Length).TrimStart('\', '/')
        $data['artifactFormat'] = $exported.Format
        $data['lastReExportedAt'] = (Get-Date).ToUniversalTime().ToString('o')
        Write-Meta -RootPath $root -Data $data
    } else {
        Write-Log WARN '-SkipReExport: media artifact may be stale relative to host changes.'
    }

    if (-not $PSCmdlet.ShouldProcess($wslName, "Unregister host-local distro '$wslName' (media artifact retained)")) {
        $Script:ExitCode = 5
        throw 'USER_CANCELLED'
    }

    Stop-WslClean
    Invoke-Wsl -Arguments @('--unregister', $wslName)

    $data2 = Convert-MetaToHashtable (Read-Meta $root)
    $data2['hostInstallPath'] = $null
    $data2['lastEjectedAt'] = (Get-Date).ToUniversalTime().ToString('o')
    $data2['lastHost'] = $env:COMPUTERNAME
    Write-Meta -RootPath $root -Data $data2

    Write-Log OK 'Host distro unregistered. Media export retained. Eject the drive in Explorer.'
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
    $known = @(
        'USER_CANCELLED', 'WSL_NOT_FOUND', 'EXPORT_EMPTY', 'SMOKE_FAILED', 'DISTRO_NOT_FOUND',
        'ROOT_REQUIRED', 'USB_NOT_FOUND', 'WSL_LIST_FAILED', 'WSL1_UNSUPPORTED', 'BACKUP_NO_DISTRO',
        'BACKUP_DISTRO_MISSING', 'BACKUP_DIR_REQUIRED', 'ARTIFACT_MISSING', 'NAME_EXISTS', 'ROOT_MISSING',
        'NAME_REQUIRED', 'HOST_PATH_ON_MEDIA', 'UNSAFE_UNREGISTER', 'DISTRO_REQUIRED'
    )
    if ($msg -notin $known) {
        Write-Log ERROR $msg
    }
    if ($msg -eq 'USER_CANCELLED') {
        Write-Log WARN 'Cancelled by user.'
    }
}

exit $Script:ExitCode
