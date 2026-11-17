# Compact — VHDX 压缩

> 状态：**规划中**（`.\WslKit.ps1 Compact` 目前仅打印说明）。

压缩 WSL2 发行版虚拟磁盘，回收已删除文件占用的稀疏空间。

入口：

```powershell
.\WslKit.ps1 Compact -Distro <name>
.\WslKit.ps1 Compact Run -Distro <name>
```

---

## 规划中的用法

```powershell
# 查看说明
.\WslKit.ps1 Compact Help

# 压缩指定发行版（实现后）
.\WslKit.ps1 Compact Run -Distro Ubuntu
```

---

## 规划步骤

### 1. 查找 VHDX 位置

```powershell
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\*" |
  Select-Object DistributionName, BasePath |
  Format-Table -AutoSize
```

WSL 默认文件名常为 `ext4.vhdx` / `file.vhdx`，需兼容被重命名的校验。

### 2. 压缩

1. `wsl --shutdown`
2. 启动 `diskpart`（静默、无弹窗）
3. `select vdisk file="path\to\file.vhdx"`
4. `compact vdisk`
5. 在控制台显示压缩进度

---

## 安全要点（规划）

- 压缩前必须停干净 WSL，避免损坏虚拟盘。
- 操作前建议先用 Usb 模块做一次 `-Backup`。
- 勿在发行版 Running 时直接 compact。
