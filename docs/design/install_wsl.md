## TODO: WSL installation

安装 WSL + OpenEuler linux WSL 发行版

检查当前系统是否满足安装 WSL 要求，验证通过后安装最新 WSL 运行时。

参见 [openEuler WSL Installation](https://www.openeuler.org/en/wiki/install/wsl) 安装指南，从 [openEuler Repo](https://repo.openeuler.org/openEuler-24.03-LTS/WSL) 下载最新安装包，此链接始终只会提供最新版 LTS，完整下载链接例如 `https://repo.openeuler.org/openEuler-24.03-LTS/WSL/openEuler-WSL-24.03.zip`，以管理员身份启动 PowerShell 终端，并在包中运行 `Add-AppDevPackage.ps1` 脚本。

注意事项：

* 不要使用 Microsoft Store 安装 OpenEuler。
* 静默安装，禁止弹窗。
* 显示安装进度。
* 使用纯 PowerShell 脚本实现功能。
