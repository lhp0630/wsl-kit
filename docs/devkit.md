# Devkit — 工具预装

> 状态：**规划中**（`.\WslKit.ps1 Devkit` 目前仅打印说明）。

支持 Ubuntu、openEuler 等 WSL 发行版；通用 CPU 架构；bash / zsh；支持离线安装（先在线 Prepare）。

实现以 **纯 bash** 为主（Windows 入口只做调度）。

入口：

```powershell
.\WslKit.ps1 Devkit
.\WslKit.ps1 Devkit Run
.\WslKit.ps1 Devkit Prepare
# 或
.\WslKit.ps1 Devkit -Prepare
```

---

## 规划中的用法

```powershell
# 说明
.\WslKit.ps1 Devkit Help

# 在线：预下载二进制，供离线机使用
.\WslKit.ps1 Devkit Prepare

# 在目标发行版内安装（实现后；离线可加 --offline）
.\WslKit.ps1 Devkit Run
```

对应调度：

```text
.\WslKit.ps1 Devkit Prepare  →  wsl ... bash prepare.sh
.\WslKit.ps1 Devkit Run      →  wsl ... bash install.sh [--offline]
```

---

## 规划功能

- 安装 zsh，切换当前 shell 为 zsh
- Linux 安装带中国大陆代理/镜像的 Homebrew
- 通过 dockpod 安装 docker + compose；可选 podman + compose
- 安装 uv（Python 工具链），二进制 → `~/.local/bin`
- 可选安装 nvm
- 安装 git
- 安装 vim（发行版包管理器 apt / dnf|yum，不用 brew）
- 安装 tmux（发行版包管理器 apt / dnf|yum，不用 brew）
- 安装 lazygit
- 安装 gh，二进制 → `~/.local/bin`
- 可选安装 cursor-agent
- 可选安装 just，二进制 → `~/.local/bin`
- 安装日志：错误日志与详细日志分两份文件
- 安装清单（JSON）：落盘工具名称、安装形式（如 `binary`、`brew`、`apt`、`yum`、`npm`、`uv`、`pip`）；不支持用户自定义；不做复杂 URL 校验
- 离线安装时跳过不支持离线的应用，并记录未成功安装的日志
- 下载层统一 `curl`，支持环境变量代理；可选 mirror 前缀（如 ghproxy）为**单一配置项**，不为每个 URL 手写多套

---

## 清单表格

钉死版本；仅 Linux；约 2026-11。支持离线指：可通过 Prepare 缓存资源，在无外网时安装。

| 工具 | 版本 | 安装形式 | 支持离线 |
|------|------|----------|----------|
| gh | v2.104.0 | binary | ✅ |
| dockpod | v4.0.0 | binary | ✅ |
| uv | 0.13.8 | binary | ✅ |
| lazygit | v0.66.3 | binary | ✅ |
| just | 1.59.0 | binary | ✅ |
| nvm | v0.41.0 | binary（源码包） | ✅ |
| cursor-agent | 2026.11.13-eacade1 | binary（可选） | ✅ |
| git | 发行版仓库 | apt / dnf\|yum | ❌ |
| zsh | 发行版仓库 | apt / dnf\|yum | ❌ |
| vim | 发行版仓库 | apt / dnf\|yum | ❌ |
| tmux | 发行版仓库 | apt / dnf\|yum | ❌ |
| homebrew | HEAD install.sh | brew | ❌ |

---

## 清单（资源地址）

### 二进制 / 可 Prepare 缓存

- gh（v2.104.0）— https://github.com/cli/cli/releases/tag/v2.104.0
  - x86: https://github.com/cli/cli/releases/download/v2.104.0/gh_2.104.0_linux_amd64.tar.gz
  - aarch64: https://github.com/cli/cli/releases/download/v2.104.0/gh_2.104.0_linux_arm64.tar.gz
  - sums: https://github.com/cli/cli/releases/download/v2.104.0/gh_2.104.0_checksums.txt

- dockpod（v4.0.0）— https://github.com/diphyx/dockpod/releases/tag/v4.0.0
  - x86: https://github.com/diphyx/dockpod/releases/download/v4.0.0/dockpod-v4.0.0-amd64.tar.gz
  - aarch64: https://github.com/diphyx/dockpod/releases/download/v4.0.0/dockpod-v4.0.0-arm64.tar.gz
  - sums: https://github.com/diphyx/dockpod/releases/download/v4.0.0/checksums.txt

- uv（0.13.8）— https://github.com/astral-sh/uv/releases/tag/0.13.8
  - x86: https://github.com/astral-sh/uv/releases/download/0.13.8/uv-x86_64-unknown-linux-gnu.tar.gz
  - aarch64: https://github.com/astral-sh/uv/releases/download/0.13.8/uv-aarch64-unknown-linux-gnu.tar.gz
  - sums: https://github.com/astral-sh/uv/releases/download/0.13.8/sha256.sum

- lazygit（v0.66.3）— https://github.com/jesseduffield/lazygit/releases/tag/v0.66.3
  - x86: https://github.com/jesseduffield/lazygit/releases/download/v0.66.3/lazygit_0.66.3_linux_x86_64.tar.gz
  - aarch64: https://github.com/jesseduffield/lazygit/releases/download/v0.66.3/lazygit_0.66.3_linux_arm64.tar.gz
  - sums: https://github.com/jesseduffield/lazygit/releases/download/v0.66.3/checksums.txt

- just（1.59.0）— https://github.com/casey/just/releases/tag/1.59.0
  - x86: https://github.com/casey/just/releases/download/1.59.0/just-1.59.0-x86_64-unknown-linux-musl.tar.gz
  - aarch64: https://github.com/casey/just/releases/download/1.59.0/just-1.59.0-aarch64-unknown-linux-musl.tar.gz
  - sums: https://github.com/casey/just/releases/download/1.59.0/SHA256SUMS

- nvm（v0.41.0，源码包，架构无关）— https://github.com/nvm-sh/nvm/releases/tag/v0.41.0
  - x86: https://github.com/nvm-sh/nvm/archive/refs/tags/v0.41.0.tar.gz
  - aarch64: https://github.com/nvm-sh/nvm/archive/refs/tags/v0.41.0.tar.gz
  - sums: （上游 release 无独立 checksums 文件；catalog 内钉死 sha256，Prepare 时本地校验）

- cursor-agent（2026.11.13-eacade1，可选）— 来自 https://cursor.com/install 钉死的 lab 包
  - x86: https://downloads.cursor.com/lab/2026.11.13-eacade1/linux/x64/agent-cli-package.tar.gz
  - aarch64: https://downloads.cursor.com/lab/2026.11.13-eacade1/linux/arm64/agent-cli-package.tar.gz
  - sums: （官方未提供 checksums 文件；Prepare 时自行计算并写入 catalog 的 sha256）

### 包管理 / 安装器

- git（method: apt / dnf|yum；offline: 无预置 binary URL，离线跳过或依赖本机源缓存）
  - x86: （发行版包，无统一 URL）
  - aarch64: （发行版包，无统一 URL）
  - sums: （由发行版仓库提供）

- zsh（method: apt / dnf|yum；装后 chsh；offline: 同 git）
  - x86: （发行版包，无统一 URL）
  - aarch64: （发行版包，无统一 URL）
  - sums: （由发行版仓库提供）

- vim（method: apt / dnf|yum；offline: 同 git）
  - x86: （发行版包，无统一 URL）
  - aarch64: （发行版包，无统一 URL）
  - sums: （由发行版仓库提供）

- tmux（method: apt / dnf|yum；offline: 同 git）
  - x86: （发行版包，无统一 URL）
  - aarch64: （发行版包，无统一 URL）
  - sums: （由发行版仓库提供）

- homebrew（method: brew 官方安装流程 + 大陆镜像配置；offline: false，离线跳过）
  - x86: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  - aarch64: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  - sums: （官方 install.sh 无固定 release checksums；不按 binary 清单缓存，在线安装）

---

## 选型说明

- **安装形式优先级（全局）：二进制（binary）→ 发行版包管理器（apt / dnf|yum）→ brew（仅补充）。** Devkit 设计是二进制优先（钉版本 URL + checksum，落盘 `~/.local/bin`，可 Prepare 离线）；无合适上游 binary 时再用包管理器；brew 只做补充通道，不作为默认依赖。
- **vim / tmux：选用 apt / dnf|yum，不用 brew（也无作为默认 binary）。** 对 WSL 上的 Ubuntu / openEuler 更稳：与发行版依赖一致、不依赖 Homebrew 先装成功、安装快、失败面小；也更贴合离线/弱网（可走本机源缓存，而 brew 已标 offline: false）。上游虽可自行编译或找第三方包，但不纳入默认 binary 清单，以免维护成本与校验链过重。
- brew 的优点是版本更新、跨发行版版本更齐，但 Linuxbrew 更重，且把 vim/tmux 绑在 brew 上会放大「brew 失败则基础编辑器/会话工具都没有」的风险。
- 若将来需要更新的 vim/tmux，可另作可选 `method: brew` 或自建 binary 覆盖，默认路径仍保持包管理器。

---

## 落地方案（摘要）

仓库内维护钉死版本的 `catalog.json`：为每个 Linux 架构（x86_64 / aarch64）写完整下载 URL + sha256。多参考 aqua-registry、mise/asdf、offline bundle 类项目。上游有 sha256sums 时，Prepare 必须再拉 SUM 做二次校验。

规划目录：

```text
kits/devkit/
  catalog.json             # 钉死的资源清单（唯一真相）
  prepare.sh               # 在线：按 arch 下载 → 校验 → 写入 cache/
  install.sh               # Run：在线或 --offline 从 cache 装
  lib/
    log.sh                 # verbose.log + error.log
    detect.sh              # 已安装则跳过；识别 apt vs dnf
    fetch.sh               # curl + sha256；不执行远程 sh
    install_binary.sh      # 解压到 ~/.local/bin
    install_pkg.sh         # git/zsh/vim/tmux 走包管理
  cache/                   # Prepare 产物（gitignore；可打成 release 包）
  manifest.installed.json  # 运行后落盘：name + method
```

---

## 约束 / 安全要点（规划）

- 安装任何应用/插件前必须检查是否已存在，存在则跳过
- 禁止使用来源不明的第三方一键安装脚本
- 使用纯 bash 实现功能
- 提供 **Prepare**：在线预下载二进制，供离线安装
- 优先二进制，安装到 `~/.local/bin`
- 上游有 sha256sums 时，Prepare 必须拉 SUM 做二次校验
