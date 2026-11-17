#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit — unified entry for WSL tooling modules.

.DESCRIPTION
  Dispatches to kit modules:
    Usb      — VHDX portable on USB / directory (Usbkit.ps1)
    Compact  — VHDX compact (planned)
    Install  — WSL + openEuler install (planned)
    Devkit   — in-distro tool bootstrap (planned)

.EXAMPLE
  .\WslKit.ps1 Help
.EXAMPLE
  .\WslKit.ps1 Usb Move -Distro Ubuntu -Root E:\WSL\Ubuntu -Backup -Confirm
.EXAMPLE
  .\WslKit.ps1 Compact -Distro Ubuntu
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Usb', 'Compact', 'Install', 'Devkit', 'Help')]
    [string]$Kit = 'Help',

    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$KitArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-WslKitHelp {
    @"
WSLkit — toolkit for Windows Subsystem for Linux

TLDR: .\WslKit.ps1 Usb Help

MODULES
  Usb       VHDX portable kit (Move / Import / Eject / Backup / Status)  [ready]
  Compact   Compact WSL2 VHDX via diskpart                               [planned]
  Install   Install WSL runtime + openEuler distro                       [planned]
  Devkit    Bootstrap zsh / brew / docker / uv / git / ... in distro     [planned]

USAGE
  .\WslKit.ps1 <Module> [module-args...]
  .\WslKit.ps1 Help

EXAMPLES
  .\WslKit.ps1 Usb Move -Distro Ubuntu -Root E:\WSL\Ubuntu -Backup -Confirm
  .\WslKit.ps1 Usb Import -Root E:\WSL\Ubuntu -Start
  .\WslKit.ps1 Usb Eject -Root E:\WSL\Ubuntu -Backup
  .\WslKit.ps1 Compact -Distro Ubuntu
  .\WslKit.ps1 Install
  .\WslKit.ps1 Devkit -Prepare

NOTES
  Run on Windows PowerShell 5.1+ / PowerShell 7+, not inside a Linux shell.
  If RemoteSigned blocks a GitHub ZIP extract: Unblock-File .\WslKit.ps1
  Or: powershell -ExecutionPolicy Bypass -File .\WslKit.ps1 Help
"@ | Write-Host
}

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

switch ($Kit) {
    'Help' {
        Show-WslKitHelp
        exit 0
    }
    'Usb' {
        $script = Join-Path $root 'kits\Usbkit.ps1'
        if (-not (Test-Path -LiteralPath $script)) {
            Write-Error "Missing module script: $script"
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
