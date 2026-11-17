#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Devkit module — bootstrap tools inside a WSL distro (PLANNED).

.DESCRIPTION
  Planned in-distro bootstrap; see docs/devkit.md. Bash-first; Ubuntu /
  openEuler; bash/zsh; online Prepare + offline Run.

.EXAMPLE
  .\WslKit.ps1 Devkit
.EXAMPLE
  .\WslKit.ps1 Devkit -Prepare
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Help', 'Run', 'Prepare')]
    [string]$Command = 'Help',

    [switch]$Prepare
)

Set-StrictMode -Version Latest

if ($Prepare) { $Command = 'Prepare' }

function Show-Help {
    @"
Devkit — in-distro developer tool bootstrap  [PLANNED]

STATUS
  Not implemented yet. Design notes: docs/devkit.md

PLANNED USAGE
  .\WslKit.ps1 Devkit              # help / status
  .\WslKit.ps1 Devkit Run          # install inside current/default distro
  .\WslKit.ps1 Devkit Prepare      # online: prefetch binaries for offline install
  .\WslKit.ps1 Devkit -Prepare

PLANNED FEATURES
  - zsh (+ set as default shell)
  - Homebrew with China mainland mirrors/proxy
  - docker+compose via dockpod (optional podman+compose)
  - uv / gh / lazygit / just → ~/.local/bin
  - optional nvm, cursor-agent
  - git; catalog.json + Prepare offline; skip if installed
  - verbose/error logs + JSON install manifest (name + method)
  - Ubuntu & openEuler; bash/zsh
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[PLANNED] Devkit Run is not implemented yet. See docs/devkit.md' -ForegroundColor Yellow
        exit 2
    }
    'Prepare' {
        Write-Host '[PLANNED] Devkit Prepare is not implemented yet. See docs/devkit.md' -ForegroundColor Yellow
        exit 2
    }
}
