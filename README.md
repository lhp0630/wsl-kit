# WslKit

面向 [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/windows/wsl/) 的工具套件。

统一入口：[WslKit.ps1](WslKit.ps1)。

## Why WslKit?

- 在多台 Windows 之间带走同一套 Wsl Linux。
- 自动生命周期管理，导出、导入、备份、注销与默认用户恢复，减少毁掉镜像的可能性。
- 在单一入口下扩展压缩磁盘、安装发行版、预装开发工具等能力（部分仍为规划中）。

Portable 默认 `export`/`import`，手写 `import-in-place` 往往更简单，但运行期绑在移动盘上且注销更危险；两种模式的取舍见 [docs/portable.md](docs/portable.md)。

## Features

- **Portable：** Move / Import / Eject / Backup / Status — 介质保存导出产物；日常在本机磁盘导入运行；Eject 注销本机副本并默认 ReExport 回介质。
- **Compact：** 压缩 WSL2 VHDX（规划）。
- **Install：** 安装 WSL 运行时与 openEuler 等发行版（规划）。
- **Devkit：** 发行版内工具预装，支持 Prepare 离线包（规划）。

## Requirements

- Windows 10/11，WSL2 可用。
- Windows PowerShell 5.1+ 或 PowerShell 7+。
- 可移动介质建议 NTFS；跨机带走时建议 BitLocker；优先 USB3 固态移动盘。

## Quick Start

```powershell
# 若从 GitHub ZIP 解压且 RemoteSigned 拦截：
# Unblock-File .\WslKit.ps1; Unblock-File .\kits\*.ps1
# 或：powershell -ExecutionPolicy Bypass -File .\WslKit.ps1 Help

.\WslKit.ps1 Help
.\WslKit.ps1 Portable Help
```

Portable 最短路径：

```powershell
.\WslKit.ps1 Portable Move -Distro Ubuntu -Root E:\WSLkit -Backup -Confirm
.\WslKit.ps1 Portable Import -Root E:\WSLkit -Start -Confirm
.\WslKit.ps1 Portable Eject -Root E:\WSLkit -Confirm
```

## How It Works

**当前默认（`export` / `import`）：** 可移动介质上存放冷导出（`.vhdx` / `.tar`）；插入后 `wsl --import` 到本机路径（默认 `%USERPROFILE%\WSLkit\<Name>`）；使用期间 VHDX 在本机磁盘；拔出前将改动写回介质（可跳过）并 `unregister` **本机**登记，介质上的导出物保留。换来的是跨机清晰、本机性能、以及注销不误伤介质金样。

**远期可选（`import-in-place`）：** 虚拟盘文件直接驻留在介质上，用 `wsl --import-in-place` 登记后就地运行——通常更快，但日常 I/O 依赖移动盘。当前未实现。

各规划模块由 `WslKit.ps1` 调度到 `kits\` 占位脚本；实现前设计笔记在 `docs/design\`。

## Usage

```powershell
.\WslKit.ps1 <模块> [参数...]

.\WslKit.ps1 Portable Move|Import|Eject|Backup|Status|Help ...
.\WslKit.ps1 Compact Help
.\WslKit.ps1 Install Help
.\WslKit.ps1 Devkit Help
```

| 模块 | 文档 |
|------|------|
| Portable | [docs/portable.md](docs/portable.md) |
| Compact | [docs/compact_vdisk.md](docs/compact_vdisk.md) |
| Install | [docs/install_wsl.md](docs/install_wsl.md) |
| Devkit | [docs/devkit.md](docs/devkit.md) |

旧名 `Usb` 仍可作为别名调用，但会提示改用 `Portable`。

## Safety and Limitations

- 导出前会停干净 WSL。
- `wsl --unregister` 会删除该发行版**本机 InstallLocation** 下的虚拟盘；因此 Import 的 HostPath **不得**落在介质 Root 下，避免误删介质上的导出金样。
- 导出物含用户数据与密钥；请加密可移动盘。
- Import 按镜像体积可能耗时较长；日常 I/O 受益于本机磁盘。
- Compact / Install / Devkit 尚未实现。
- 不保证劣质 USB 闪存盘上的 export/import 耐久。

## Documentation

- 模块说明：[`docs/`](docs/)
- 调研：[`docs/research/`](docs/research/README.md)
- RFC：[`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)
- 设计草稿：[`docs/design/`](docs/design/)（非正式决策）

## License

见 [LICENSE](LICENSE)。
