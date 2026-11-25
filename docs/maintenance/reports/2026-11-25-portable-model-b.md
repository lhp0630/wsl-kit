# Portable Model B implementation (RFC-ARCH-001)

- **Date:** 2026-11-25
- **RFC:** [RFC-ARCH-001](../../../RFCs/RFC-ARCH-001-portable-vdisk-lifecycle.md)
- **Status:** Done (Model B shipped; Phase 2 not started)
- **Rename:** Module / script / user doc later renamed **Usb → Portable** (`Usbkit.ps1` → `Portable.ps1`, `usb.md` → `portable.md`). Paths below use current names.

## What landed

| Area | Change |
|------|--------|
| Code | [`kits/Portable.ps1`](../../../kits/Portable.ps1) Model B (export → host import → eject unregister host; default re-export on eject) |
| Entry | [`WslKit.ps1`](../../../WslKit.ps1) Portable dispatch; `Usb` alias warns |
| Docs | [`docs/portable.md`](../../portable.md), [`README.md`](../../../README.md) rewritten for Model B; Phase 2 marked future |
| Help | All kit Help prints Chinese-only |

## Docs governance (RFC §13.1)

| Task | Status |
|------|--------|
| D1 `docs/portable.md` | Done |
| D2 README Model B | Done |
| D3 Cross-links | Done |
| D4 research README pointer | Done |
| D5 docs-structure.mdc | Done |
| D6 design/ bulk rewrite | Skipped (per RFC) |
| D7 This report | Done |

## Smoke

```powershell
.\WslKit.ps1 Help
.\WslKit.ps1 Portable Help
```
