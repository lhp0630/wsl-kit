#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Compact module — compact WSL2 VHDX (PLANNED).

.DESCRIPTION
  Planned flow (see docs/design/compact_vdisk.md):
    1. Resolve VHDX path from LXSS registry (DistributionName / BasePath)
    2. wsl --shutdown
    3. diskpart: select vdisk + compact vdisk (silent, show progress)

.EXAMPLE
  .\WslKit.ps1 Compact -Distro Ubuntu
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Help', 'Run')]
    [string]$Command = 'Help',

    [string]$Distro
)

Set-StrictMode -Version Latest

function Show-Help {
    @"
Compact — WSL2 VHDX compact  [PLANNED]

STATUS
  Not implemented yet. Design notes: docs/compact_vdisk.md

PLANNED USAGE
  .\WslKit.ps1 Compact -Distro <name>
  .\WslKit.ps1 Compact Run -Distro <name>

PLANNED STEPS
  1. Locate VHDX via HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
  2. Accept renamed vhdx (not only ext4.vhdx / file.vhdx)
  3. wsl --shutdown
  4. diskpart compact vdisk (no UI popup; show progress)
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[PLANNED] Compact is not implemented yet. See docs/compact_vdisk.md' -ForegroundColor Yellow
        if ($Distro) { Write-Host "Requested distro: $Distro" }
        exit 2
    }
}
