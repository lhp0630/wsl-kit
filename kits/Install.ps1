#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Install module — install WSL + openEuler (PLANNED).

.DESCRIPTION
  Planned flow (see docs/design/install_wsl.md):
    - Verify host meets WSL requirements
    - Install latest WSL runtime
    - Download openEuler WSL package from repo.openeuler.org (latest LTS)
    - Silent install via Add-AppDevPackage.ps1 (no Store; show progress)

.EXAMPLE
  .\WslKit.ps1 Install
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Help', 'Run')]
    [string]$Command = 'Help'
)

Set-StrictMode -Version Latest

function Show-Help {
    @"
Install — WSL runtime + openEuler distro  [PLANNED]

STATUS
  Not implemented yet. Design notes: docs/install_wsl.md

PLANNED USAGE
  .\WslKit.ps1 Install
  .\WslKit.ps1 Install Run

PLANNED BEHAVIOR
  - Check Windows prerequisites for WSL
  - Install latest WSL runtime
  - Download from openEuler LTS WSL repo (e.g. openEuler-24.03-LTS/WSL)
  - Do NOT use Microsoft Store for openEuler
  - Silent install, no popups; show progress
  - Pure PowerShell
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[PLANNED] Install is not implemented yet. See docs/install_wsl.md' -ForegroundColor Yellow
        exit 2
    }
}
