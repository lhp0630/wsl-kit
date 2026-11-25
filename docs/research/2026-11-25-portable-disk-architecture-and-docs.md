# WSL 可移动磁盘便携：架构模型、模块命名与设计文档留存

- **角色：** `docs/research/` 下**当前研究结论主入口**（扁平 + 日期文件名；索引见 [`README.md`](./README.md)）
- **日期：** 2026-11-25（结论修订：同日锁定默认模型 B）
- **范围：** 跨 Windows 使用可移动磁盘上的 WSL2 发行版；是否需要架构 RFC；便携模块是否改名为 `Go`；`docs/design/` 是否保留；**默认生命周期模型**
- **性质：** 调研报告（历史决策依据）。产品默认模型 B 已在 **RFC-ARCH-001 Implemented**（2026-11-25）落地；Phase 2 驻留仍未实现。模块名随后定为 **Portable**（旧名 Usb / `Usbkit.ps1` / `docs/usb.md`）。
- **证据来源（调研当日路径，现已更名）：** 历史会话设计；[`README.md`](../../README.md)；现 [`docs/portable.md`](../portable.md)；现 [`kits/Portable.ps1`](../../kits/Portable.ps1)；[`docs/design/`](../design/)；任务参考流程；专项对比 [`supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md`](./supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md)

---

## 1. 已核实事实（Verified facts）

> 下表描述**调研当日**仓库状态（模型 A + 模块名 Usb）。落地后见 Portable + 模型 B。

| 事实（调研当日） | 证据 |
|------|------|
| 产品入口为 `WslKit.ps1`，按模块调度便携模块 / `Compact` / `Install` / `Devkit` | `WslKit.ps1`；`README.md` |
| 便携脚本当时为 `kits/Usbkit.ps1`，文档为 `docs/usb.md`（现 `Portable.ps1` / `portable.md`） | 仓库路径 |
| **调研当日实现语义**偏向 **VHDX 驻留**：`Move` 优先 `--manage --move`；`Import` 优先 `import-in-place`；`Eject` **默认不** `unregister` | 当时用户文档 / Help |
| 用户可见流程为 Move / Import / Eject，可选 `-Backup`，`meta.json` 记录 `defaultUser` 等 | 当时用户文档 |
| `docs/design/` 含 Compact / Install / Devkit 的实现前设计笔记（含钉死版本清单等） | `docs/design/*.md` |
| 任务给出的参考流程是另一套模型：介质上保留 **export 产物**；导入到**本机路径**；拔出前 **unregister**；进入时用 `-u <用户名>` | 任务正文（非当前默认实现） |

---

## 2. 两种便携架构模型（Survey）

### 模型 A — VHDX 驻留可移动介质（当前实现主路径）

```text
Move    → 把发行版盘落到 USB/指定 Root（--move 或 export/import 到 Root）
Import  → 本机登记 Root 上的 vhdx（import-in-place）
Eject   → shutdown；默认不 unregister；再弹出介质
```

| 优点 | 缺点 |
|------|------|
| 少一次「导入到本机再整盘拷」；同机同盘符可快速续用 | 盘符变化 / 换机需重新登记；USB 随机写性能差 |
| 与「插上即用」叙事接近 | `unregister` 危险（可能删掉介质上的 vhdx）→ 默认禁止 |
| | 多机残留失效登记需额外处理 |

### 模型 B — 导出到介质 + 本机 import 副本（任务参考流程）

```text
迁出:
  wsl --shutdown
  wsl --export … backup.tar          # 可选冷备份
  wsl --export … ubuntu.vhd --format vhd / --vhd
  wsl --unregister …                 # 注销源机登记（删的是源 InstallLocation）

插入另一台:
  wsl --shutdown
  wsl --import Name LocalInstallPath \media\ubuntu.vhd --vhd
  wsl -d Name -u <user>              # 用户名来自迁出前记录

拔出:
  wsl --shutdown
  wsl --unregister Name              # 删的是本机 InstallLocation 副本
  弹出介质（介质上仍保留 .vhd / .tar）
```

| 优点 | 缺点 |
|------|------|
| 日常运行在本机磁盘，性能更好 | 每次插入有 import 成本；介质与本机各持一份语义要讲清 |
| 拔出时 unregister **针对本机副本**，与「带走介质」一致 | 必须避免对「介质上唯一 vhdx」做 import-in-place 后再 unregister |
| 换机路径清晰；用户名可经 meta 恢复 `-u` / `wsl.conf` | 与调研当日驻留实现不一致，需迁移文档与实现 |

### 关键横切需求（两模型皆需）

- 迁出前 `wsl --shutdown`（或等价停干净）。
- 记录 **defaultUser**（meta / catalog）；导入后恢复，避免长期以 root 使用。
- 可选冷备份（tar 或第二份 vhdx）。
- NTFS + 足够空间；建议 BitLocker。

---

## 3. 重点结论

### 3.1 架构设计是否需要 RFC？

**建议：需要。** 理由：

1. 模型 A（已实现）与模型 B（任务参考）在 **Eject 是否 unregister、VHDX 落点、换机路径** 上互斥，属于产品语义级选择。
2. 影响 CLI、`meta.json`、安全默认值与用户文档；不可仅靠 `docs/design` 笔记或代码注释定案。
3. 符合「实质架构 / 破坏性语义变更 → RFC」的治理习惯（参见 smtgit `RFCs/README.md` 精神）。

**不需要**为每个规划模块（Compact / Install / Devkit）立即各写一篇架构 RFC；可在主生命周期 RFC 落地后，按模块成熟度另开 Feature RFC。

→ 已起草草案：[`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)（**Draft**，待维护者审阅）。

### 3.2 便携模块是否建议重命名为 `Go`（`WslKit.ps1 Go …`）？

**建议：不采用 `Go` 作为模块名。**

| 候选 | 评价 |
|------|------|
| **Go** | 与 Go 语言 / `go` 工具链严重撞名；对英文读者几乎必然误解；路径名 `wslgo` 亦强化语言联想 |
| **Usb**（调研当日名） | 表达「可移动介质」；略窄（也可迁到固定第二磁盘）但仍可理解 |
| **Portable** / **Carry** / **Disk** | 更贴「跨机带走」语义；略长或略泛 |
| **Media** | 中性；稍抽象 |

**调研建议（供维护者选一）：**

1. 短期可保留旧名，避免无收益的破坏性 CLI 变更。  
2. 若要强调「跨 Windows 带走」而非「仅 USB」，采用 **`Portable`**（`WslKit.ps1 Portable …`），并用兼容 shim。  
3. **不要**仅因路径示例 `wslgo` 而采用模块名 `Go`。

**落地结果：** 模块已更名为 **Portable**；`Usb` 仅作警告别名；拒绝 `Go`。

### 3.3 `docs/design/` 是否需要保留？

**建议：短期保留，并明确边界；不要与 research / RFC 混用。**

| 文档树 | 回答的问题 | 处置 |
|--------|------------|------|
| `docs/design/` | 模块实现前工作草稿（清单、步骤、选型笔记） | **保留**；继续排除在「用户文档治理」之外（与任务一致） |
| `docs/research/` | 学到了什么、有哪些选项 | 新建；本报告落于此 |
| `RFCs/` | 应该做什么、为什么 | 新建；架构取舍进 RFC |

**不建议**立刻删除 `docs/design/`：Devkit 等钉死 URL / 选型说明仍有信息价值，且用户文档 `docs/devkit.md` 已与之对齐。  
**建议**在 README **Documentation** 中一句话区分：用户说明 → `docs/*.md`；设计草稿 → `docs/design/`；决策 → `RFCs/`；调研 → `docs/research/`。  
待对应 RFC Accepted 且实现稳定后，可将 design 中过时段落标 deprecated 或迁入 research archive，再考虑精简目录。

---

## 4. 设计提案摘要（调研层已锁定方向；RFC 仍为 Draft）

| 议题 | 提案 | 需 RFC？ |
|------|------|----------|
| 便携生命周期**默认** | **模型 B**（export → 本机 import → Eject unregister 本机副本） | 已写入 [`RFC-ARCH-001`](../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md) |
| `import-in-place` / 驻留（模型 A） | **远期可选（Phase 2）**；首版不实现 | 纳入 ARCH-001 Phase 2；不必另开架构 RFC |
| 删除并重写便携脚本 | **建议作为 ARCH-001 实现阶段**，不另开架构 RFC | 见下 §4.1 |
| 默认用户 | 迁出前 meta；导入后 `wsl.conf` / `-u` | 纳入 ARCH-001 |
| 模块名 | 拒绝 `Go`；后续定为 **Portable** | 已落地 |
| `docs/design/` | 保留 + 角色说明；用户文档治理任务见 ARCH-001 §13.1 | 否 |

### 4.1 重写便携脚本：另开 RFC 还是改 ARCH-001？

**建议：调整并沿用当前架构 RFC（ARCH-001），不要为「删光重写」另开架构 RFC。**

| 做法 | 评价 |
|------|------|
| **修订 ARCH-001**（推荐） | 重写是模型 B 的交付手段，与「默认 B」同一决策；RFC 内写清实现范围、文档治理、Phase 2 即可 |
| 另开 Feature/Arch RFC 只谈重写 | 重复决策、双份状态机；仅当重写夹带模块更名、大范围 CLI 拆分等新决策时才值得 |

用户文档在 ARCH-001 **Accepted 之前**可继续描述**当时代码（模型 A）**，并链到调研/RFC；Accepted 后按 RFC §13.1 治理为模型 B（现 [`docs/portable.md`](../portable.md)）。

---

## 5. 开放假设 / 待维护者确认

- [x] 产品默认生命周期：**模型 B**（ARCH-001 Implemented）
- [x] 本机 InstallLocation 默认根路径：`%USERPROFILE%\WSLkit\<Name>`
- [x] Eject 默认 re-export；`-SkipReExport` 可跳过
- [x] 模块名：**Portable**（排除 `Go`；`Usb` 为警告别名）
- [ ] `docs/design/` 对外可见程度（README 已有一行指针则通常足够）

---

## 6. 参考

- [`docs/portable.md`](../portable.md)（Model B）
- [`supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md`](./supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md)
- [`RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md`](../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)
- Microsoft WSL：`wsl --export` / `--import` / `--import-in-place` / `--unregister` / `--manage --move`
- 治理参照（结构）：smtgit `docs/research/` + `RFCs/` 三分法
