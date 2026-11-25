# Install

> 状态：**规划中**（`.\WslKit.ps1 Install` 目前仅打印说明）。

检查主机是否满足 WSL 条件，安装最新 WSL 运行时，并安装 openEuler 等发行版（不用 Microsoft Store）。

## 命令

```powershell
.\WslKit.ps1 Install Help
.\WslKit.ps1 Install Run
```

## 关键语义

| 步骤 | 含义 |
|------|------|
| 前置检查 | 验证 Windows / 虚拟化等相关条件 |
| 运行时 | 安装或更新 WSL |
| 发行版 | 从 openEuler LTS WSL 仓库下载包并静默安装 |

参考：[openEuler WSL Installation](https://www.openeuler.org/en/wiki/install/wsl)、[openEuler WSL 仓库](https://repo.openeuler.org/openEuler-24.03-LTS/WSL)。

## 工作流程（规划）

1. 检查环境。
2. 安装最新 WSL 运行时。
3. 下载 openEuler WSL 包（例如 `openEuler-WSL-24.03.zip`）。
4. 管理员 PowerShell 中静默运行包内 `Add-AppDevPackage.ps1`，显示进度、禁止弹窗。

## 示例

```powershell
.\WslKit.ps1 Install Help
.\WslKit.ps1 Install Run
```

## 安全要点（规划）

- 不要使用 Microsoft Store 安装 openEuler。
- 静默安装；纯 PowerShell。
- 建议管理员权限。

## 相关代码 / 设计

- 占位：[`kits/Install.ps1`](../kits/Install.ps1)
- 设计草稿：[`docs/design/install_wsl.md`](design/install_wsl.md)
