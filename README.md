# WSLkit

面向 [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/) 的工具套件。

*TLDR: 直接看 [用法示例](docs/) 获取分步指南。*

统一入口是 PowerShell 脚本 [WslKit.ps1](WslKit.ps1)，按模块调度：

| 模块 | 脚本 | 状态 | 文档 |
|------|------|------|------|
| **Usb** | [kits/Usbkit.ps1](kits/Usbkit.ps1) | 可用 | [docs/usb.md](docs/usb.md) |
| **Compact** | [kits/Compact.ps1](kits/Compact.ps1) | 规划中 | [docs/compact_vdisk.md](docs/compact_vdisk.md) |
| **Install** | [kits/Install.ps1](kits/Install.ps1) | 规划中 | [docs/install_wsl.md](docs/install_wsl.md) |
| **Devkit** | [kits/Devkit.ps1](kits/Devkit.ps1) | 规划中 | [docs/devkit.md](docs/devkit.md) |

```powershell
.\WslKit.ps1 Help
.\WslKit.ps1 Usb Help
```

> 在 **Windows** PowerShell 5.1+ / PowerShell 7+ 中运行。  
> GitHub ZIP + `RemoteSigned`：先 `Unblock-File .\*.ps1`，或 `powershell -ExecutionPolicy Bypass -File .\WslKit.ps1 Help`。

---

## 主要功能

### Usb — VHDX 便携（可用）

把发行版 VHDX 迁到 U 盘/指定目录，插上导入、拔前安全停机；支持迁移/卸载前冷备份。

→ 用法、参数、流程、安全要点见 **[docs/usb.md](docs/usb.md)**。

### Compact — VHDX 压缩（规划中）

定位发行版 VHDX 后，用 `diskpart compact vdisk` 压缩（静默、显示进度）。

→ **[docs/compact_vdisk.md](docs/compact_vdisk.md)**

### Install — WSL + openEuler（规划中）

检测环境 → 安装 WSL 运行时 → 从 openEuler 仓库静默安装发行版（不用 Store）。

→ **[docs/install_wsl.md](docs/install_wsl.md)**

### Devkit — 工具预装（规划中）

在发行版内预装 zsh / brew / dockpod / uv / git / vim / tmux / lazygit / gh 等；二进制优先，支持 Prepare 离线包与 JSON 安装清单。

→ **[docs/devkit.md](docs/devkit.md)**

---

## 仓库布局

```text
WslKit.ps1          # 统一入口
kits/               # Usb / Compact / Install / Devkit 模块
docs/               # 各模块说明（用法 / 参数 / 流程）
docs/design/        # 设计文档（实现前）
README.md
LICENSE
```
