#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Install 模块 — 安装 WSL + openEuler（规划中）。

.DESCRIPTION
  规划流程（见 docs/design/install_wsl.md）：
    - 校验主机是否满足 WSL 要求
    - 安装最新 WSL 运行时
    - 从 repo.openeuler.org 下载 openEuler WSL 包（最新 LTS）
    - 经 Add-AppDevPackage.ps1 静默安装（不走商店；显示进度）

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
Install — 安装 WSL 运行时与 openEuler 发行版  [规划中]

状态
  尚未实现。设计说明：docs/install_wsl.md

规划用法
  .\WslKit.ps1 Install
  .\WslKit.ps1 Install Run

规划行为
  - 检查 Windows 对 WSL 的前置条件
  - 安装最新 WSL 运行时
  - 从 openEuler LTS WSL 仓库下载（如 openEuler-24.03-LTS/WSL）
  - 不通过 Microsoft Store 安装 openEuler
  - 静默安装、无弹窗；显示进度
  - 纯 PowerShell
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[规划中] Install 尚未实现。详见 docs/install_wsl.md' -ForegroundColor Yellow
        exit 2
    }
}
