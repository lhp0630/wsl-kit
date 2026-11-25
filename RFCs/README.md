# RFCs

RFCs (Requests for Comments) propose, review, accept, and record substantial design and process decisions for **WSLkit**.

## What an RFC is

An RFC answers: **What should we do and why?**

Related document types (do not substitute for each other):

| Location | Question |
|----------|----------|
| **`RFCs/`** (this tree) | What should we do and why? |
| [`docs/research/`](../docs/research/README.md) | What have we learned and what should we consider? |
| [`docs/design/`](../docs/design/) | Pre-implementation working notes (not a decision record) |
| [`docs/maintenance/reports/`](../docs/maintenance/reports/) | What did we actually do and what happened? |

## When an RFC is required

Propose an RFC when the change is substantial, including:

- Portable-disk lifecycle semantics (Move / Import / Eject, unregister defaults).
- Module rename or breaking CLI surface (`WslKit.ps1 <Module> …`).
- Documentation governance or release/security policy changes.
- Decisions that should remain as historical project record.

Routine bug fixes and small documentation clarifications normally do **not** need an RFC.

Prefer a research report under `docs/research/` when options are still open; promote a choice into an RFC when Maintainers need a decision record.

## How to propose

1. Read [`process.md`](process.md).
2. Copy [`TEMPLATE.md`](TEMPLATE.md) to `RFC-<AREA>-<NNN>-short-title.md`.
3. Fill applicable sections; mark unknowns as open questions.
4. Request Maintainer review (PR or equivalent).

Do **not** assign `Accepted` yourself. AI agents may draft and revise; only a human Maintainer may accept, reject, defer, or supersede.

## Lifecycle (summary)

```text
Draft → In Review → Accepted → In Progress → Implemented
                 ↘ Rejected
                 ↘ Deferred
         Accepted → Superseded (by a later RFC)
```

## Current inventory

| RFC | Title | Status |
|-----|-------|--------|
| [RFC-ARCH-001](./RFC-ARCH-001-portable-vdisk-lifecycle.md) | Portable VDisk lifecycle (**default Model B**; resident/`import-in-place` = Phase 2) | Implemented |

## References

- Process: [`process.md`](process.md)
- Template: [`TEMPLATE.md`](TEMPLATE.md)
- Research supporting ARCH-001: [`docs/research/2026-11-25-portable-disk-architecture-and-docs.md`](../docs/research/2026-11-25-portable-disk-architecture-and-docs.md)
