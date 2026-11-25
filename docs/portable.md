# Portable

将 WSL2 发行版以 **方案 B（export-import）** 方式带到可移动介质，并在 Windows 主机上使用：

1. **Move** — 导出到介质，然后注销**源机**发行版  
2. **Import** — 从介质 `import` 到**本机** InstallLocation（默认 `%USERPROFILE%\WSLkit\<Name>`）  
3. **Eject** — 将本机改动 re-export 回介质（可用 `-SkipReExport` 跳过），注销**本机**副本，再弹出介质  

实现：[`kits/Portable.ps1`](../kits/Portable.ps1)。规范：[`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)。

> **第二阶段（远期，未实现）：** 介质上 VHDX 驻留 + `import-in-place`。首版不提供。  
> 旧模块名 `Usb` / `Usbkit.ps1` / `docs/usb.md` 已更名为 **Portable**；`.\WslKit.ps1 Usb …` 仍可调用但会警告。

入口：

```powershell
.\WslKit.ps1 Portable <Command> ...
# 或
.\kits\Portable.ps1 <Command> ...
```

---

## 命令

```powershell
.\WslKit.ps1 Portable Move|Migrate|Import|Eject|Backup|Status|Help [options]
```

| 选项 | 必需 | 默认 | 说明 |
|------|------|------|------|
| `-Distro` | Move/Backup | — | 源发行版名 |
| `-Root` | 常要 | — | 介质工作区（含 `meta.json`、`distros\`） |
| `-MediaLabel` | 否 | — | 按卷标解析 Root（相对 `WSLkit`）；兼容别名 `-UsbLabel` |
| `-Name` | 否 | 源名 / meta | 本机登记名与产物基名 |
| `-DefaultUser` | 否 | 探测 / meta | 默认 Linux 用户 |
| `-HostRoot` | 否 | `%USERPROFILE%\WSLkit` | Import 时本机父目录（其下再建 `<Name>`） |
| `-Backup` | 否 | 关 | Move/Eject 前额外冷备份到 `backups\` |
| `-BackupDir` | 否 | `<Root>\backups` | 备份目录 |
| `-Start` | 否 | 关 | Import 后 `wsl -d … [-u user]` |
| `-SkipReExport` | 否 | 关 | Eject 时不把本机状态写回介质（介质可能过期） |
| `-SkipHash` | 否 | 关 | 导出跳过 SHA256 |
| `-Force` | 否 | 关 | Import 时若同名已登记则先注销本机副本 |
| `-Confirm` / `-WhatIf` | 否 | — | 确认 / 演练 |

`Migrate` 为 `Move` 的别名。

---

## 关键语义

| 概念 | 含义 |
|------|------|
| 介质 Root | 存放 `meta.json`、`distros\<Name>.vhdx|tar`、`backups\`、`logs\` |
| lifecycle | `export-import`（方案 B） |
| hostInstallPath | Import 后本机 InstallLocation；Eject unregister 只针对本机副本 |
| defaultUser | 迁出前写入 meta；Import 后写 `/etc/wsl.conf`，`-Start` 可带 `-u` |

介质布局：

```text
<Root>/
  meta.json
  distros/
    <Name>.vhdx   # 或 .tar（降级）
  backups/
  logs/
```

---

## 工作流程

### Move / Migrate

1. 可选 `-Backup`。  
2. `wsl --shutdown` → export 到 `distros\`（优先 VHD；失败则 `.tar`）。  
3. 写 `meta.json`（含 `defaultUser`、`lifecycle`）。  
4. 校验产物非空后 `wsl --unregister` **源机**发行版。

### Import

1. 读 meta，定位介质产物。  
2. 本机路径：`-HostRoot\<Name>` 或 `%USERPROFILE%\WSLkit\<Name>`（**不得**落在介质 Root 下）。  
3. `wsl --import <Name> <HostPath> <Artifact> [--vhd] --version 2`。  
4. 恢复 defaultUser；冒烟；可选 `-Start`。

### Eject

1. 可选 `-Backup`。  
2. 默认将本机发行版 **re-export** 回介质产物（`-SkipReExport` 可跳过）。  
3. `shutdown` → `unregister` **本机**登记。  
4. 提示在资源管理器中弹出介质（介质上仍保留导出物）。

---

## 示例

```powershell
.\WslKit.ps1 Portable Help

# 迁出到移动盘
.\WslKit.ps1 Portable Move -Distro Ubuntu -Root E:\WSLkit -Backup -Confirm

# 另一台机器插入后
.\WslKit.ps1 Portable Import -Root E:\WSLkit -Start -Confirm

# 带走前
.\WslKit.ps1 Portable Eject -Root E:\WSLkit -Confirm

.\WslKit.ps1 Portable Status -Root E:\WSLkit
.\WslKit.ps1 Portable Import -MediaLabel WSLKIT -Confirm
```

---

## 退出码

| 码 | 含义 |
|----|------|
| 0 | 成功 |
| 2 | 前置失败 |
| 3 | 备份/导出失败 |
| 4 | 迁移/导入失败 |
| 5 | 用户取消 |

---

## 安全要点

- 任何导出前会 `wsl --shutdown`。  
- **unregister 只应对本机 InstallLocation**；方案 B 禁止把 HostPath 设在介质 Root 下。  
- 导出物含密钥与家目录；介质建议 **NTFS + BitLocker**，优先 USB3 固态盘。  
- 从旧「驻留 Root」用法迁移：先对旧环境做一次 Move/export 到新布局，或等待第二阶段。  
- ZIP + `RemoteSigned`：`Unblock-File .\WslKit.ps1`、`Unblock-File .\kits\*.ps1`。

---

## 相关代码

- 入口：[`WslKit.ps1`](../WslKit.ps1)  
- 模块：[`kits/Portable.ps1`](../kits/Portable.ps1)  
- RFC：[`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)  
- 调研：[`docs/research/`](research/README.md)
