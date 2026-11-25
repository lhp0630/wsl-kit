# Devkit

> 状态：**规划中**（`.\WslKit.ps1 Devkit` 目前仅打印说明）。

在 Ubuntu / openEuler 等 WSL 发行版内预装开发工具；通用 CPU 架构；bash / zsh；支持离线（先 Prepare）。实现以 **纯 bash** 为主（Windows 入口只做调度）。

## 命令

```powershell
.\WslKit.ps1 Devkit Help
.\WslKit.ps1 Devkit Prepare
.\WslKit.ps1 Devkit Run
.\WslKit.ps1 Devkit -Prepare
```

| 选项 / 子命令 | 说明 |
|---------------|------|
| `Prepare` / `-Prepare` | 在线预下载可缓存二进制 |
| `Run` | 在发行版内安装（可 `--offline`，规划中） |

```text
.\WslKit.ps1 Devkit Prepare  →  wsl … bash prepare.sh
.\WslKit.ps1 Devkit Run      →  wsl … bash install.sh [--offline]
```

## 关键语义

- **安装形式优先级：** binary → apt/dnf|yum → brew（仅补充）。
- **清单：** 钉死版本的 `catalog.json`（完整 URL + sha256）；不支持用户自定义复杂 URL 校验。
- **离线：** Prepare 可缓存的标 ✅；包管理器 / brew 默认 ❌（跳过并记日志）。

### 清单表格（摘要）

| 工具 | 版本 | 安装形式 | 支持离线 |
|------|------|----------|----------|
| gh | v2.104.0 | binary | ✅ |
| dockpod | v4.0.0 | binary | ✅ |
| uv | 0.13.8 | binary | ✅ |
| lazygit | v0.66.3 | binary | ✅ |
| just | 1.59.0 | binary | ✅ |
| nvm | v0.41.0 | binary（源码包） | ✅ |
| cursor-agent | 2026.11.13-eacade1 | binary（可选） | ✅ |
| git / zsh / vim / tmux | 发行版仓库 | apt / dnf\|yum | ❌ |
| homebrew | HEAD install.sh | brew | ❌ |

完整 URL 与选型说明见设计草稿（资源地址以 design 为准，本页保持用户向摘要）。

## 工作流程（规划）

1. `Prepare`：按 arch 下载 → checksum → `cache/`。
2. `Run`：已安装则跳过；binary 从 cache/URL 安装到 `~/.local/bin`；包管理类走 apt/dnf；离线跳过不支持项。
3. 落盘 verbose/error 日志与 `manifest.installed.json`（name + method）。

## 示例

```powershell
.\WslKit.ps1 Devkit Help
.\WslKit.ps1 Devkit Prepare
.\WslKit.ps1 Devkit Run
```

## 安全要点（规划）

- 安装前检查是否已存在。
- 禁止来源不明的一键 `curl \| sh`（官方 brew 安装流程除外且标离线不可用）。
- 上游有 sha256sums 时 Prepare 必须二次校验。

## 选型说明

- **全局：** binary → 发行版包管理器 → brew（补充）。
- **vim / tmux：** 用 apt/dnf|yum，不用 brew，也不作为默认 binary。

## 相关代码 / 设计

- 占位：[`kits/Devkit.ps1`](../kits/Devkit.ps1)
- 设计草稿（含完整资源地址）：[`docs/design/devkit.md`](design/devkit.md)
