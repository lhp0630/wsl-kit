#Requires -Version 5.1
<#
.SYNOPSIS
  WSLkit Compact 模块 — 压缩 WSL2 VHDX（规划中）。

.DESCRIPTION
  规划流程（见 docs/design/compact_vdisk.md）：
    1. 从 LXSS 注册表解析 VHDX 路径（DistributionName / BasePath）
    2. wsl --shutdown
    3. diskpart：select vdisk + compact vdisk（无弹窗，显示进度）

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
Compact — 压缩 WSL2 VHDX  [规划中]

状态
  尚未实现。设计说明：docs/compact_vdisk.md

规划用法
  .\WslKit.ps1 Compact -Distro <名称>
  .\WslKit.ps1 Compact Run -Distro <名称>

规划步骤
  1. 经 HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss 定位 VHDX
  2. 接受已重命名的 vhdx（不仅限 ext4.vhdx / file.vhdx）
  3. wsl --shutdown
  4. diskpart compact vdisk（无 UI 弹窗；显示进度）
"@ | Write-Host
}

switch ($Command) {
    'Help' { Show-Help; exit 0 }
    'Run' {
        Write-Host '[规划中] Compact 尚未实现。详见 docs/compact_vdisk.md' -ForegroundColor Yellow
        if ($Distro) { Write-Host "请求的发行版: $Distro" }
        exit 2
    }
}
