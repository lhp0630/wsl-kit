# RFC: Portable VDisk lifecycle (default Model B)

- **RFC ID:** RFC-ARCH-001
- **Title:** Portable VDisk lifecycle (default Model B)
- **Status:** Implemented
- **Type:** Architecture
- **Authors:** WSLkit contributors (drafted with AI assistance)
- **Created:** 2026-11-25
- **Updated:** 2026-11-25
- **Supersedes:** N/A
- **Superseded by:** N/A
- **Accepted / implemented:** 2026-11-25 — Maintainer directed “按 RFC-ARCH-001 落地”; Model B shipped in `kits/Portable.ps1` (formerly `Usbkit.ps1`); Phase 2 still pending.
- **Rename note:** Module / script / user doc renamed **Usb → Portable** (`WslKit.ps1 Portable …`, `kits/Portable.ps1`, `docs/portable.md`); `Usb` remains a warning shim; `-UsbLabel` aliases `-MediaLabel`.

---

## 1. Summary

**Default** the Portable module to **Model B**: export artifact on removable media → `wsl --import` into a **host-local** InstallLocation → on eject, `wsl --unregister` that **host copy** only (media keeps the export). Capture `defaultUser` for post-import `-u` / `wsl.conf`.

**Rewrite** `kits/Portable.ps1` (formerly `Usbkit.ps1`) for Model B (full replacement of the resident-oriented implementation is in scope for this RFC’s implementation phase — **do not** open a separate architecture RFC solely for that rewrite).

**`import-in-place` / VHDX-resident (Model A)** is a **future optional mode** (远期可选), not part of the first Model B ship. Document the intent now; implement later under this RFC’s “Phase 2” or a thin follow-up Feature RFC only if the optional surface needs separate review.

This RFC does **not** rename the module to `Go`. The product name is **Portable** (not `Usb`).

---

## 2. Context and problem statement

At draft time, the then-named Usb module ([`kits/Usbkit.ps1`](../kits/Portable.ps1) / [`docs/usb.md`](../docs/portable.md)) followed **Model A** (VHDX resident on Root; Import prefers `import-in-place`; Eject defaults to **no** `unregister`). Current paths are Portable.

The cross-PC portable story and stability/speed research favor **Model B** (export on media, run on host disk, unregister host on eject). See:

- [`docs/research/2026-11-25-portable-disk-architecture-and-docs.md`](../docs/research/2026-11-25-portable-disk-architecture-and-docs.md)
- [`docs/research/supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md`](../docs/research/supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md)

Maintainer direction for this draft: **default = Model B**; resident / `import-in-place` = **远期可选**.

### 2.1 Rewrite vs new RFC (normative guidance)

| Question | Decision in this RFC |
|----------|----------------------|
| Delete then-current portable kit code and reimplement Model B? | **Yes, in implementation phase of ARCH-001** (after acceptance) |
| Open a **new** architecture RFC for the rewrite? | **No** — same lifecycle decision; rewrite is delivery of this RFC |
| When would a **new** RFC be warranted? | Only if later work changes CLI module name again, adds a large optional Resident surface with new safety rules, or splits Portable into multiple modules |

---

## 3. Motivation

- Safer `unregister` (host copy ≠ media gold copy).
- Better day-to-day I/O (VHDX on internal disk).
- Clear cross-Windows narrative aligned with Microsoft export/import transfer guidance.
- Avoid dual unnamed defaults.

---

## 4. Goals

- Lock **Model B as the product default** for `WslKit.ps1 Portable`.
- Specify migrate / import / eject / backup / meta (`defaultUser`, `lifecycle`).
- Authorize **full replacement** of the then-current kit implementation after acceptance.
- Schedule **documentation governance** for the new default (README + `docs/portable.md` + cross-links); `docs/design/` remains out of routine user-doc rewrites unless needed for pointers.
- Record **Phase 2**: optional resident / `import-in-place` mode (not in first ship).

## 5. Non-goals

- Shipping Model A / `import-in-place` in the first Model B release.
- Renaming the module to `Go`.
- Compact / Install / Devkit implementation.
- WSL1 support.

## 6. Constraints and assumptions

- PowerShell entry; `wsl.exe` only.
- Media preferably NTFS; BitLocker recommended.
- Default `import` **copies** into host-local InstallLocation — never treat media-only VHDX as the unregister target in default mode.
- Probe `--vhd` / `--format vhd`; degrade to `.tar` with docs warning if needed.
- Until Phase 2 ships, remove or stub any user-facing resident/`import-in-place` paths so docs and code match Model B only.

## 7. Proposed design

### 7.1 Default Model B verbs

| Verb | Behavior |
|------|----------|
| **Move** (or alias **Migrate**) | `shutdown` → optional Backup → `export` VHD(X)/tar **onto media** → write `meta.json` (`defaultUser`, `lifecycle: export-import`, artifact paths) → verify artifact → `unregister` **source host** distro |
| **Import** | `shutdown` → `wsl --import <Name> <HostLocalPath> <MediaArtifact> [--vhd]` → restore default user → optional `wsl -d <Name> -u <user>` (`-Start`) |
| **Eject** | optional Backup / optional re-export of dirty host copy back to media (open question §15) → `shutdown` → `unregister` **host-local** distro → prompt Explorer safe eject |
| **Backup** / **Status** | Cold backup helpers; show meta + registration state |

Default host path template (informative): `%USERPROFILE%\WSLkit\<Name>` (avoid `wslgo` in defaults).

### 7.2 Phase 2 (远期可选) — Resident / `import-in-place`

| Item | Plan |
|------|------|
| When | After Model B is Implemented and documented; not blocking first ship |
| What | Opt-in mode: VHDX lives on media; `import-in-place`; Eject **must not** unregister by default |
| Docs | Separate subsection under `docs/portable.md`; warn unregister deletes media VHDX |
| RFC | Prefer amend ARCH-001 Phase 2 checklist; open Feature RFC only if CLI/safety surface is large |

### 7.3 Implementation approach (Portable kit)

After acceptance:

1. Replace the portable kit script with a Model B implementation (delete obsolete resident-first code paths rather than maintaining dual defaults). Script path today: `kits/Portable.ps1`.
2. Update `WslKit.ps1` Help text for Portable (Chinese-only Help prints).
3. Module name is **Portable**; keep a short-lived `Usb` CLI alias that warns.
4. No parallel “legacy” binary unless Maintainers request a temporary shim.

---

## 8. Alternatives considered

| Alternative | Summary | Why not chosen |
|-------------|---------|----------------|
| Keep Model A default | Prior resident code | Weaker eject safety & runtime I/O for portable media |
| New RFC only for “rewrite kit” | Split decision from delivery | Same architecture; duplicates ARCH-001 |
| Ship A and B as equal modes on day one | Max flexibility | Foot-guns; docs/support cost |
| Rename to `Go` | Short name | Collides with Go language |

## 9. Trade-off analysis

- **Benefits:** Clear default; safer unregister; faster day-to-day use; single story for agents/docs.
- **Costs:** Full kit rewrite; slower “dock” (import); breaking change vs prior resident users.
- **Phase 2** restores advanced resident users without blocking B.

## 10. Compatibility and migration

- Breaking: users relying on resident Root + no-unregister Eject must migrate to export layout or wait for Phase 2.
- Migration note in `docs/portable.md`: one-time export from old Root, then use Model B.
- `meta.json`: require/prefer `lifecycle: export-import` for default path.

## 11. Security and privacy

- BitLocker on media; exports hold secrets.
- Default path: unregister only host-local InstallLocation recorded at Import.
- Confirm before unregister / overwrite.

## 12. Testing and validation

Manual:

1. Move/Migrate to media with Backup; source unregistered; artifact + meta OK.
2. Import to `%USERPROFILE%\WSLkit\…`; `-u` / default user OK.
3. Eject: host gone; media artifact remains; Explorer eject OK.
4. Refuse/document any default path that unregister would hit media-only VHDX.
5. Docs governance checklist (§13.1) completed.

## 13. Rollout and rollback

### 13.1 Documentation governance tasks (normative after acceptance; before or with code land)

Do **not** treat `docs/design/` as the user manual. Governance applies to:

| # | Task | Owner after Accept |
|---|------|--------------------|
| D1 | Rewrite [`docs/portable.md`](../docs/portable.md) for **Model B only** as the described default (命令 / 关键语义 / 工作流程 / 示例 / 退出码 / 安全 / 相关代码); mark Phase 2 resident as “未实现 / 远期” | Docs + implementer |
| D2 | Update [`README.md`](../README.md) Features / How It Works / Usage / Safety to Model B; link research + this RFC under Documentation | Docs |
| D3 | Ensure Compact / Install / Devkit user docs still link correctly; no accidental Model A assumptions in cross-links | Docs |
| D4 | Update [`docs/research/README.md`](../docs/research/README.md) inventory if primary stance text needs a one-line “default B locked in ARCH-001” pointer | Docs |
| D5 | Update [`.cursor/rules/docs-structure.mdc`](../.cursor/rules/docs-structure.mdc) (or future `AGENTS.md`) so agents describe Model B as intended default once Accepted | Docs / agents |
| D6 | **Exclude** bulk rewrites of [`docs/design/`](../docs/design/) unless adding a one-line pointer to ARCH-001 | — |
| D7 | After code lands: optional [`docs/maintenance/reports/YYYY-MM-DD-portable-model-b.md`](../docs/maintenance/reports/) execution report | Implementer |

Order recommendation: **Accept RFC → D1–D5 (docs may land ahead of or with code) → implement Portable kit → D7**.

### 13.2 Code rollout

- Accept this RFC (Maintainer).
- Replace kit; ship Model B as Portable.
- Rollback: revert git tag/commit; docs rollback with same revert.

## 14. Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Import-in-place used against media then unregister | Data loss | Not in default; Phase 2 forbids unregister-by-default |
| Users expect old resident behavior | Breakage | Migration notes; Phase 2 roadmap |
| Eject without re-export | Stale media snapshot | Document; optional dirty re-export (§15) |
| Dual docs (A in portable.md, B in RFC) during Draft | Confusion | User doc stays “current code” until Accept + D1 |

## 15. Open questions

- [x] Maintainer formal **Accept** of ARCH-001 (Model B default)? — accepted via implement directive 2026-11-25
- [x] Default InstallLocation template — `%USERPROFILE%\WSLkit\<Name>` (override with `-HostRoot`)
- [x] Eject re-export — **default re-export**; `-SkipReExport` to skip
- [x] Verb `Move` kept; `Migrate` alias added
- [x] Module name — **Portable** (reject `Go`; `Usb` kept as warning alias)
- [ ] Phase 2 resident / `import-in-place` — still future work

## 16. References

- Research primary + supplementary (stability/speed)
- [`docs/portable.md`](../docs/portable.md) (Model B)
- Implementation: [`kits/Portable.ps1`](../kits/Portable.ps1)
- Maintenance report: [`docs/maintenance/reports/2026-11-25-portable-model-b.md`](../docs/maintenance/reports/2026-11-25-portable-model-b.md)
- WSL: `--export` / `--import` / `--unregister` / `--import-in-place`
