# Install — WSL + openEuler

> 状态：**规划中**（`.\WslKit.ps1 Install` 目前仅打印说明）。

检查主机是否满足 WSL 条件，安装最新 WSL 运行时，并安装 openEuler Linux WSL 发行版。

入口：

```powershell
.\WslKit.ps1 Install
.\WslKit.ps1 Install Run
```

---

## 规划中的用法

```powershell
.\WslKit.ps1 Install Help
.\WslKit.ps1 Install Run   # 实现后：检测 → 装运行时 → 装 openEuler
```

参考：

- [openEuler WSL Installation](https://www.openeuler.org/en/wiki/install/wsl)
- [openEuler Repo（始终指向最新 LTS）](https://repo.openeuler.org/openEuler-24.03-LTS/WSL)

示例包地址：`https://repo.openeuler.org/openEuler-24.03-LTS/WSL/openEuler-WSL-24.03.zip`  
以管理员身份在包中运行 `Add-AppDevPackage.ps1`。

---

## 规划流程

1. 检查当前系统是否满足安装 WSL 的要求
2. 验证通过后安装最新 WSL 运行时
3. 下载 openEuler WSL 安装包（不用 Microsoft Store）
4. 静默执行包内安装脚本，控制台显示进度

---

## 安全 / 约束要点（规划）

- **不要**使用 Microsoft Store 安装 openEuler。
- 静默安装，禁止弹窗；显示安装进度。
- 使用纯 PowerShell 实现。
- 建议在管理员 PowerShell 中运行。
