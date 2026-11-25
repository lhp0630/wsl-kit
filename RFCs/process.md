# RFC process

## Status values

| Status | Meaning | Who may set |
|--------|---------|-------------|
| Draft | Authoring in progress | Authors / agents |
| In Review | Awaiting Maintainer decision | Authors after self-check |
| Accepted | Maintainers approved the design direction | **Maintainer only** |
| In Progress | Implementation underway against an Accepted RFC | Maintainer / lead implementer |
| Implemented | Behavior and docs match the Accepted RFC | **Maintainer only** (after verify) |
| Rejected | Will not adopt | **Maintainer only** |
| Deferred | Not now; may revisit | **Maintainer only** |
| Superseded | Replaced by a newer RFC | **Maintainer only** |

Agents MUST NOT mark Accepted / Rejected / Deferred / Implemented / Superseded without explicit human Maintainer authorization.

## Acceptance vs implementation

- **Acceptance** = the project agrees this is the design to pursue.
- **Implementation complete** = code + user docs match the accepted design.

A merged code PR alone does **not** accept an RFC.

## Review checklist

- Problem and evidence are clear.
- Goals / non-goals are explicit.
- At least one meaningful alternative is analyzed when a choice exists.
- Compatibility, security (especially `unregister`), and rollback are considered.
- Open questions that block acceptance are listed.
- Related research is linked when applicable.

## Filing layout

```text
RFCs/
  README.md
  process.md
  TEMPLATE.md
  RFC-AREA-NNN-short-title.md     # active drafts / in-review
  accepted/                       # optional copies or moves when accepted
  rejected/
  deferred/
  superseded/
```

Small repos MAY keep Accepted RFCs in the top-level `RFCs/` folder and only use subfolders when the set grows.
