#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Devkit 模块 — 在发行版内预装开发工具（规划中）。

.DESCRIPTION
  规划中的发行版内引导；见 docs/devkit.md。以 Bash 为主；
  Ubuntu / openEuler；bash/zsh；在线 Prepare + 离线 Run。

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
Devkit — 发行版内开发工具预装  [规划中]

状态
  尚未实现。设计说明：docs/devkit.md

规划用法
  .\WslKit.ps1 Devkit              # 帮助 / 状态
  .\WslKit.ps1 Devkit Run          # 在当前/默认发行版内安装
  .\WslKit.ps1 Devkit Prepare      # 在线：预取二进制供离线安装
  .\WslKit.ps1 Devkit -Prepare

规划能力
  - zsh（并设为默认 shell）
  - Homebrew（国内镜像 / 代理）
  - docker+compose（经 dockpod；可选 podman+compose）
  - uv / gh / lazygit / just → ~/.local/bin
  - 可选 nvm、cursor-agent
  - git；catalog.json + Prepare 离线包；已安装则跳过
  - 详细/错误日志 + JSON 安装清单（名称 + 方式）
  - Ubuntu 与 openEuler；bash/zsh
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[规划中] Devkit Run 尚未实现。详见 docs/devkit.md' -ForegroundColor Yellow
        exit 2
    }
    'Prepare' {
        Write-Host '[规划中] Devkit Prepare 尚未实现。详见 docs/devkit.md' -ForegroundColor Yellow
        exit 2
    }
}
