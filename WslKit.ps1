#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit — WSL 工具套件统一入口。

.DESCRIPTION
  按模块调度：
    Portable — 便携发行版（export 到介质 / import 到本机 / 弹出）
    Compact  — 压缩 VHDX（规划中）
    Install  — 安装 WSL + openEuler（规划中）
    Devkit   — 发行版内工具预装（规划中）

.EXAMPLE
  .\WslKit.ps1 Help
.EXAMPLE
  .\WslKit.ps1 Portable Move -Distro Ubuntu -Root E:\WSLkit -Backup -Confirm
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Portable', 'Usb', 'Compact', 'Install', 'Devkit', 'Help')]
    [string]$Kit = 'Help',

    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$KitArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 兼容旧模块名 Usb → Portable
if ($Kit -eq 'Usb') {
    Write-Warning '模块名 Usb 已更名为 Portable，请改用: .\WslKit.ps1 Portable ...'
    $Kit = 'Portable'
}

function Show-WslKitHelp {
    @"
WSLkit — Windows Subsystem for Linux 工具套件

快速查看：.\WslKit.ps1 Portable Help

模块
  Portable  便携：Move / Import / Eject / Backup / Status（export/import） [可用]
  Compact   压缩 WSL2 VHDX（diskpart）                              [规划中]
  Install   安装 WSL 运行时与 openEuler 发行版                        [规划中]
  Devkit    发行版内预装 zsh / brew / docker / uv / git 等             [规划中]

用法
  .\WslKit.ps1 <模块> [模块参数...]
  .\WslKit.ps1 Help

示例
  .\WslKit.ps1 Portable Move -Distro Ubuntu -Root E:\WSLkit -Backup -Confirm
  .\WslKit.ps1 Portable Import -Root E:\WSLkit -Start
  .\WslKit.ps1 Portable Eject -Root E:\WSLkit -Confirm
  .\WslKit.ps1 Compact -Distro Ubuntu
  .\WslKit.ps1 Install
  .\WslKit.ps1 Devkit -Prepare

说明
  Portable：介质存 export 产物，本机 wsl --import 运行；远期可选 import-in-place（未实现）。
  详见 docs/portable.md 与 RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md。
  请在 Windows PowerShell 5.1+ / PowerShell 7+ 中运行，不要在 Linux shell 内执行入口脚本。
  若 GitHub ZIP 解压后被 RemoteSigned 拦截：Unblock-File .\WslKit.ps1
  或：powershell -ExecutionPolicy Bypass -File .\WslKit.ps1 Help
"@ | Write-Host
}

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

switch ($Kit) {
    'Help' {
        Show-WslKitHelp
        exit 0
    }
    'Portable' {
        $script = Join-Path $root 'kits\Portable.ps1'
        if (-not (Test-Path -LiteralPath $script)) {
            Write-Error "缺少模块脚本: $script"
            exit 1
        }
        if ($null -eq $KitArgs -or $KitArgs.Count -eq 0) {
            & $script 'Help'
        } else {
            & $script @KitArgs
        }
        exit $LASTEXITCODE
    }
    'Compact' {
        $script = Join-Path $root 'kits\Compact.ps1'
        if ($null -eq $KitArgs -or $KitArgs.Count -eq 0) { & $script 'Help' } else { & $script @KitArgs }
        exit $LASTEXITCODE
    }
    'Install' {
        $script = Join-Path $root 'kits\Install.ps1'
        if ($null -eq $KitArgs -or $KitArgs.Count -eq 0) { & $script 'Help' } else { & $script @KitArgs }
        exit $LASTEXITCODE
    }
    'Devkit' {
        $script = Join-Path $root 'kits\Devkit.ps1'
        if ($null -eq $KitArgs -or $KitArgs.Count -eq 0) { & $script 'Help' } else { & $script @KitArgs }
        exit $LASTEXITCODE
    }
}
