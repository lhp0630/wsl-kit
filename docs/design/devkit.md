目标：

支持 ubuntu、openeuler linux WSL 发行版，通用 cpu 架构，支持 bash、zsh shell 环境，支持离线环境安装。


功能：

- 安装 zsh，切换当前 shell 为 zsh。
- linux 安装具有中国大陆代理/镜像的 homebrew。
- 通过 dockpod 安装 docker、compose 工具组合，可选 podman、compose 工具组合。
- 安装 uv 工具（python 管理工具），通过二进制文件安装在 `.local/bin`。
- 可选安装 nvm 工具（node 版本管理）。
- 安装 git。
- 安装 vim（发行版包管理器 apt / dnf|yum，不用 brew）。
- 安装 tmux（发行版包管理器 apt / dnf|yum，不用 brew）。
- 安装 lazygit。
- 安装 gh，通过二进制文件安装在 `.local/bin`。
- 可选安装 cursor-agent。
- 可选安装 just，通过二进制文件安装在 `.local/bin`。
- 记录安装过程日志，错误日志与详细日志分开两份文件。
- 记录安装清单，落盘工具名称、以什么形式安装（如 binary、brew、apt、yum、npm、uv、pip）。
- 在离线环境安装，跳过不支持离线安装的应用，记录未成功安装的日志。
- 清单文件以 JSON 文件存储，不支持用户自定义，代码不实现复杂的 URL 校验。
- 下载层统一走 curl，支持环境变量代理；可选 mirror 前缀（如 ghproxy）做成单一配置项，不要每个 URL 手写多套。


清单（钉死版本；仅 Linux；版本日期约 2026-11）：

清单表格（支持离线 = 可通过 Prepare 缓存后无外网安装）：

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

二进制 / 可 Prepare 缓存：

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

非 GitHub 二进制（包管理 / 安装器；离线策略见下）：

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

选型说明：

- **安装形式优先级（全局）：二进制（binary）→ 发行版包管理器（apt / dnf|yum）→ brew（仅补充）。** Devkit 设计是二进制优先（钉版本 URL + checksum，落盘 `~/.local/bin`，可 Prepare 离线）；无合适上游 binary 时再用包管理器；brew 只做补充通道，不作为默认依赖。
- **vim / tmux：选用 apt / dnf|yum，不用 brew（也无作为默认 binary）。** 对 WSL 上的 Ubuntu / openEuler 更稳：与发行版依赖一致、不依赖 Homebrew 先装成功、安装快、失败面小；也更贴合离线/弱网（可走本机源缓存，而 brew 已标 offline: false）。上游虽可自行编译或找第三方包，但不纳入默认 binary 清单，以免维护成本与校验链过重。
- brew 的优点是版本更新、跨发行版版本更齐，但 Linuxbrew 更重，且把 vim/tmux 绑在 brew 上会放大「brew 失败则基础编辑器/会话工具都没有」的风险。
- 若将来需要更新的 vim/tmux，可另作可选 `method: brew` 或自建 binary 覆盖，默认路径仍保持包管理器。


注意事项：

- 安装任何应用/插件之前必须执行检查是否已经存在，存在则跳过安装。
- 禁止使用来源不明的第三方一键安装脚本。
- 使用纯 bash 脚本实现功能。
- 提供“预备”选项，该功能为在线环境预先下载所有二进制文件，提供在离线环境中安装。
- 优选选择二进制文件，安装在 `.local/bin`。
- 上游有 sha256sums 就 Prepare 时必须拉 SUM 做二次校验。
- 多参考 aqua-registry、mise/asdf 插件、其他开源的「offline bundle」项目设计与思路。


如何落地？

- 如何下载安装资源，开源竞品项目或开源社区采用稳定且易于维护的方案是什么？资源清单文件记录 x86 / aarch64 的完整下载地址和 SUM 文件地址？（我们只需要支持 linux）
  > 方案：仓库内维护一份「钉死版本」的 catalog.json，为每个 Linux 架构写完整下载 URL + sha256。

- 如何安全的时别发行版包管理器？
  > 方案：以 `command -v` 探测 apt-get → dnf → yum 为主，用 `cat /etc/os-release` 交叉验证发行版；只允许清单 packages 配置的白名单，如 `"packages": { "apt": ["git"], "dnf": ["git"] }`。


架构：

```
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

Windows 侧只做调度：

.\WslKit.ps1 Devkit Prepare  # → wsl ... bash prepare.sh
.\WslKit.ps1 Devkit Run      # → wsl ... bash install.sh [--offline]
```


资源清单形态：

```json
{
  "schemaVersion": 1,
  "tools": [
    {
      "id": "uv",
      "method": "binary",
      "version": "0.6.14",
      "offline": true,
      "detect": { "cmd": "uv", "version_flag": "--version" },
      "assets": {
        "linux-x86_64": {
          "url": "https://github.com/astral-sh/uv/releases/download/0.6.14/uv-x86_64-unknown-linux-gnu.tar.gz",
          "sha256": "abcd…",
          "checksums_url": "https://github.com/astral-sh/uv/releases/download/0.6.14/sha256.sum"
        },
        "linux-aarch64": {
          "url": "https://github.com/astral-sh/uv/releases/download/0.6.14/uv-aarch64-unknown-linux-gnu.tar.gz",
          "sha256": "ef01…",
          "checksums_url": "https://github.com/astral-sh/uv/releases/download/0.6.14/sha256.sum"
        }
      },
      "extract": { "type": "tar.gz", "binaries": ["uv", "uvx"] }
    },
    {
      "id": "git",
      "method": "ospackage",
      "offline": "partial",
      "packages": { "apt": ["git"], "dnf": ["git"] }
    },
    {
      "id": "homebrew",
      "method": "install_script",
      "offline": false
    }
  ]
}
```

约定：

- offline: true|false：离线 Run 直接跳过。
- checksums_url 可选：上游有 sha256.sum / checksums.txt 时，Prepare 下载后核对文件名对应行；与清单内 sha256 不一致则失败。
- method: binary|ospackage|install_script|brew|npm|uv|pip：binary 表示二进制安装，ospackage 表示发行版包管理器安装，install_script 表示官方在线脚本安装，brew、npm、uv、pip 现阶段只做占位。
