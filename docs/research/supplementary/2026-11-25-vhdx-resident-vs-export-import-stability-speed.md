# 模型 A（VHDX 驻留）vs 模型 B（export + 本机 import）：核心差异与稳定性 / 速度

- **角色：** `docs/research/supplementary/` 专项对比（独立价值；结论索引见 [`../README.md`](../README.md)）
- **日期：** 2026-11-25
- **范围：** 调研当日便携实现主路径（驻留，旧名 Usbkit）与任务参考流程（export/import + unregister）的**核心差异**；重点对比**稳定性**与**速度**
- **性质：** 调研（历史）。产品已按 ARCH-001 落地模型 B；脚本现为 [`kits/Portable.ps1`](../../../kits/Portable.ps1)。
- **关联：** 总论 [`../2026-11-25-portable-disk-architecture-and-docs.md`](../2026-11-25-portable-disk-architecture-and-docs.md)；[`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)

---

## 1. 一句话核心差异

| | **模型 A — VHDX 驻留（当前实现）** | **模型 B — 介质 export + 本机 import（任务参考）** |
|--|--------------------------------------|-----------------------------------------------------|
| **日常跑的那份盘在哪** | 可移动介质上的 **同一份** `ext4.vhdx`（本机只登记路径） | **本机磁盘**上的 import 副本；介质上主要是 **冷导出文件**（`.vhd` / `.vhdx` / `.tar`） |
| **拔出时 unregister** | **默认不能做**：unregister 会删掉登记指向的 VHDX → 可能毁掉介质上唯一副本 | **应当做**：unregister 删的是**本机 InstallLocation 副本**；介质上的导出物仍在 |
| **「插上就能用」的成本** | 多为 `import-in-place` / 路径重绑 → **秒～几十秒级** | 每次（或每机）`wsl --import … --vhd` → **按镜像体积分钟～十几分钟级** |

其余差异（盘符、默认用户、备份）都是这一核心分流生出来的。

---

## 2. 流程对照（Verified + 任务描述）

### 模型 A（仓库现状）

```text
Move   → VHDX 落到 Root（USB/目录）；本机登记指向 Root
Import → import-in-place（或等价）挂上同一文件
Eject  → shutdown；默认不 unregister；再弹出
```

证据（调研当日）：当时 `docs/usb.md` / `kits/Usbkit.ps1`；现为 [`docs/portable.md`](../../portable.md) / [`kits/Portable.ps1`](../../../kits/Portable.ps1)（模型 B）。

### 模型 B（任务参考）

```text
迁出 → shutdown →（可选 tar 备份）→ export 到介质 → unregister 源机
插入 → shutdown → import 到本机路径（如 %USERPROFILE%\…\ubuntu）→ -u 用户
拔出 → shutdown → unregister 本机 → 弹出介质
```

证据：任务正文；与微软文档「换机用 export VHD + import」叙述同族（[WSL FAQ / transfer](https://github.com/MicrosoftDocs/wsl/blob/main/WSL/faq.yml)）。

---

## 3. 稳定性对比

### 3.1 数据安全（误操作 / 注销）

| 风险 | 模型 A | 模型 B |
|------|--------|--------|
| `wsl --unregister` | **高危**：删的是介质上的 live VHDX（社区多次踩坑：external SSD 上 in-place 后再 unregister 文件被删） | **可控**：默认删本机副本；介质导出物仍在（前提是 import 时**拷到本机**，而非对介质唯一文件 in-place） |
| 未 shutdown 就拔盘 | **高危**：正在写入的 VHDX 易损 | **较低**：若已 unregister 且介质仅为冷文件；若忘记 unregister、本机仍挂着，拔的是「空」介质也不伤本机盘，但下次状态需理清 |
| 两台机器同时以为「自己拥有」同一 live 盘 | **危险**（U 盘插两台不可能，但残留登记 + 盘符错乱易操作错文件） | 每机各自本地副本；介质是快照源，冲突表现为「忘了重新 export」导致副本过期 |

**稳定性结论（数据安全）：模型 B 更稳**——把「注销」与「介质上的金样」解耦；模型 A 必须长期禁止默认 unregister，并严格 shutdown。

### 3.2 运行期可靠性（I/O、掉线、睡眠）

| 因素 | 模型 A | 模型 B |
|------|--------|--------|
| 总线 / 线材抖动、休眠恢复 | VHDX 在 USB 上，断连或休眠更易导致发行版异常、需 shutdown 修复 | 运行期依赖本机盘，USB 仅在 import/export 窗口需要稳定 |
| 文件系统 | 通常仍是 **NTFS 上的 vhdx**（不是把整个盘做成 Linux ext4 物理分区）；USB 闪存随机写差时，ext4-in-vhdx 更容易卡顿、稀疏文件膨胀 | 本机 NVMe/SATA 上同样是 vhdx，但底层介质远优于普通 U 盘 |
| 盘符变化 | Root 从 `E:`→`F:` 后登记失效，需重新 Import/绑路径 | 本机 InstallLocation 固定；介质盘符只影响「从哪读导出文件」 |

微软工程师在「WSL2 on external HDD」讨论中明确：把发行版放在 USB/HDD 上**会明显更慢**，因为实际读写更慢（[WSL Discussion #6109](https://github.com/microsoft/WSL/discussions/6109)）。社区亦证实 external 上 `import-in-place` 后 `unregister` 会删掉外部 vhdx（[WSL #9576](https://github.com/microsoft/WSL/issues/9576)）。

**稳定性结论（运行期）：模型 B 更稳**（运行与可插拔介质解耦）；模型 A 仅在 **USB3 固态移动盘 + 严谨弹出纪律** 下可接受。

### 3.3 一致性 / 心智负担

| | 模型 A | 模型 B |
|--|--------|--------|
| 「盘上是什么」 | 正在用的系统盘 | 上次带走的快照 |
| 换机后 | 可能要修登记 | 明确：import → 用 → unregister |
| 多机修改 | 同一文件串行使用 | 易出现「本机改了但介质未 re-export」 |

模型 B 若在 Eject 时**不**强制 re-export，稳定性的代价是**副本可能过期**——产品上应规定：有脏改动则 Eject 前 export 回介质（慢，但一致）。

---

## 4. 速度对比

分三段看：**迁出一次**、**每次插入（对接）**、**日常开发 I/O**。数量级为经验区间，非本仓库基准测试；随镜像大小、USB 代际、本机盘变化。

### 4.1 日常开发 I/O（最重要）

| 介质 | 模型 A（VHDX 在该介质） | 模型 B（VHDX 在本机盘） |
|------|-------------------------|-------------------------|
| 本机 NVMe/SSD | （若 Root 在本机则接近 B） | **最快**（默认预期） |
| USB3 固态移动盘 | 可用，通常明显慢于内置 SSD；随机小文件更痛 | 运行期不吃 USB；USB 只在拷贝镜像时用 |
| USB 机械盘 / 低端 U 盘 | **很慢**，不推荐做 live VHDX | 仅影响 import/export 耗时 |

WSL2 访问 `/mnt/c` 类路径另有 9P 开销；此处对比的是 **ext4.vhdx 本身落在哪块物理盘**，不是 `/mnt` 项目路径问题。

**速度结论（日常）：模型 B 显著更好**（除非 Root 已在本机高速盘上——那就不是「可移动便携」主场景）。

### 4.2 对接耗时（插上到能敲命令）

| 步骤 | 模型 A | 模型 B |
|------|--------|--------|
| 登记 / 导入 | `import-in-place`：通常 **秒级**（几乎不拷贝） | `import --vhd`：按体积 **拷贝/展开到本机**，数 GB～数十 GB 常见 **数分钟～十几分钟** |
| 首次迁出 | `--move` 或 export+import 到 USB：一次性大拷贝 | export 到介质 + unregister：一次性大拷贝（同量级） |
| 拔出 | shutdown（秒～几十秒） | shutdown + unregister（通常快）；若 Eject 还要 **re-export 脏改动**，再付一次全量/大文件写出 |

**速度结论（插拔体验）：模型 A 对接更快；模型 B 对接更慢、用起来更快。**

### 4.3 何时谁「体感更快」

| 使用模式 | 更合适 |
|----------|--------|
| 一天插拔很多台、每次只待很短、镜像很大 | **A**（避免反复全量 import） |
| 一台机器用很久、要编译/装包/I/O 重 | **B** |
| 镜像小（≤数 GB）+ USB3 SSD | 两者都可；B 仍赢在日常 I/O |
| 低端 U 盘 | **不要用 A 做 live**；B 的 export/import 也会很痛，但至少不把运行期绑死在 U 盘上 |

---

## 5. 综合判断（供 RFC 参考，非接受）

| 维度 | 更优 | 说明 |
|------|------|------|
| 数据安全（unregister / 误删） | **B** | 注销与介质金样分离 |
| 运行期稳定（掉线、休眠、USB） | **B** | 运行不依赖插头 |
| 日常开发速度 | **B** | VHDX 在本机盘 |
| 对接 / 「插上即开」速度 | **A** | in-place 几乎零拷贝 |
| 与「跨 Windows 带走」叙事一致性 | **B** | 拔出=注销本机，带走=介质上的导出物 |
| 当前仓库已实现 | **A** | 改 B 需实现 + 文档 + RFC |

**产品方向（调研层已锁定，2026-11-25）：** **默认采用模型 B**；模型 A / `import-in-place` 为 **远期可选（Phase 2）**，首版不实现。规范表述见 [`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)（**Implemented**）。

**实现备注：** 以方案 B 重写并替换便携脚本（现 `Portable.ps1`）归入 ARCH-001 实现阶段，**不建议**为此另开架构 RFC。

---

## 6. 开放假设

- [ ] 本仓库未做受控 fio/编译基准；上表为机制推论 + 上游/社区证据。
- [ ] 模型 B 是否在每次 Eject 强制 re-export：强一致则更慢，弱一致则更快但不稳。
- [ ] Phase 2 驻留模式的验收标准与文档篇幅。

## 7. 参考

- Microsoft WSL FAQ：export/import 换机与备份；unregister 破坏性说明  
- [microsoft/WSL#6109](https://github.com/microsoft/WSL/discussions/6109)（external 上发行版更慢）  
- [microsoft/WSL#9576](https://github.com/microsoft/WSL/issues/9576)（unregister 删除 external vhdx）  
- 本仓库 [`docs/portable.md`](../../portable.md)
