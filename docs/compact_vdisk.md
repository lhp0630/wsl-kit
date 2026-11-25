# Compact

> 状态：**规划中**（`.\WslKit.ps1 Compact` 目前仅打印说明）。

压缩 WSL2 发行版虚拟磁盘，回收稀疏空间。

## 命令

```powershell
.\WslKit.ps1 Compact Help
.\WslKit.ps1 Compact Run -Distro <name>
```

| 选项 | 必需 | 默认 | 说明 |
|------|------|------|------|
| `-Distro` | Run 时建议 | — | 发行版名 |

## 关键语义

从 LXSS 注册表解析 `BasePath` 下的 VHDX（兼容重命名），停机后用 `diskpart` 执行 `compact vdisk`（静默、显示进度）。

## 工作流程（规划）

1. 定位 VHDX（`HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`）。
2. `wsl --shutdown`。
3. `diskpart`：`select vdisk` → `compact vdisk`。

## 示例

```powershell
.\WslKit.ps1 Compact Help
.\WslKit.ps1 Compact Run -Distro Ubuntu
```

## 安全要点（规划）

- 压缩前必须停干净 WSL。
- 建议先用 Portable 模块做冷备份。

## 相关代码 / 设计

- 占位：[`kits/Compact.ps1`](../kits/Compact.ps1)
- 设计草稿：[`docs/design/compact_vdisk.md`](design/compact_vdisk.md)
