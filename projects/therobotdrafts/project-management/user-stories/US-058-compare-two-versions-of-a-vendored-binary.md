---
id: US-058
persona: P-004
persona_slug: trd-reverse-engineer
title: "Compare two versions of a vendored binary"
epic: "Performance & scale"
priority: P2
segment: secondary
tags: [binary-diff, versions, changed-surface, comparison]
---

# US-058 — Compare two versions of a vendored binary

**As** Sven, the reverse engineer,
**I want** compare two versions of a vendored binary and see what structurally changed,
**so that** I can focus my re-audit on the changed surface.

## Acceptance criteria
- [ ] Importing two versions produces a structural diff of added/removed/changed functions and edges
- [ ] Changed external entry points are called out specifically
- [ ] The diff is navigable and filterable to a module
- [ ] Comparing identical binaries reports 'no structural change' rather than an empty diff

## Notes
Extends US-014-style diff to binaries for incremental security re-audits.
