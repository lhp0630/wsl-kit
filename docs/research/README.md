# Research reports

Research reports capture **what we have learned** and **what we should consider** before (or alongside) a formal design decision.

## Decision-document triad

| Location | Question it answers | Typical outcome |
|----------|---------------------|-----------------|
| [`RFCs/`](../../RFCs/README.md) | What should we do and why? | Maintainer-controlled proposal / decision record |
| [`docs/research/`](./) | What have we learned and what should we consider? | Evidence, options, recommendations (**not** acceptance) |
| [`docs/maintenance/reports/`](../maintenance/reports/) | What did we actually do and what happened? | Implementation / migration execution record |

These roles MUST NOT be collapsed into a single document type.

`docs/design/` holds **pre-implementation working design notes** (module-level). It is **not** a substitute for research reports or RFCs. See the primary research entry for retention guidance.

## Directory layout

```text
docs/research/
├── README.md                 # This index
├── YYYY-MM-DD-<topic>.md     # Current / active research conclusions (flat + dated)
├── supplementary/            # Standalone topical reports that still add value
└── archive/                  # Superseded reports retained for traceability
```

**Naming:** primary reports use **flat + dated** filenames (`YYYY-MM-DD-<topic>.md`). Do **not** use a fixed evergreen name such as `research-report.md`.

## Current inventory (as of 2026-11-25)

| Role | Document | Topic |
|------|----------|-------|
| Primary | [`2026-11-25-portable-disk-architecture-and-docs.md`](./2026-11-25-portable-disk-architecture-and-docs.md) | Default **Model B**; ARCH-001 **Implemented** (see maintenance report); Phase 2 resident still future |
| Supplementary | [`supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md`](./supplementary/2026-11-25-vhdx-resident-vs-export-import-stability-speed.md) | Core diff A vs B; stability & speed; default B + Phase 2 resident |
| Archive | — | — |

## When to write a research report

- Feasibility or alternative comparison before a substantial RFC.
- Naming / information-architecture surveys that affect CLI or docs.
- Follow-on investigation requested by Maintainers after an RFC discussion.

Routine module-doc edits and small bug fixes do **not** need a research report.

## Conventions

1. Deliver research under **`docs/research/`** (not under `docs/design/` or `docs/maintenance/reports/`).
2. Distinguish **Verified facts**, **Survey findings**, **Design proposals**, and **Open assumptions**.
3. A research report MUST NOT mark an RFC Accepted or claim Maintainer approval.
4. If research leads to a design choice, draft or update an RFC under `RFCs/`; keep the research report as supporting evidence.
