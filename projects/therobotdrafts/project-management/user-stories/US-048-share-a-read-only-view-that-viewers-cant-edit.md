---
id: US-048
persona: P-003
persona_slug: trd-tech-lead
title: "Share a read-only view that viewers can't edit"
epic: "Collaboration / sharing / annotation"
priority: P3
segment: secondary
tags: [permissions, read-only, sharing, access-control]
---

# US-048 — Share a read-only view that viewers can't edit

**As** Priya, the tech lead,
**I want** share a view in read-only mode so viewers can explore but not change it,
**so that** I can show stakeholders the model without risking accidental edits.

## Acceptance criteria
- [ ] A share can be marked read-only; recipients can navigate, focus, and project but not mutate the model
- [ ] Authoring verbs are visibly disabled (dimmed) in a read-only session with an explanatory tooltip
- [ ] Read-only viewers can still add comments if comment-permission is granted separately
- [ ] An attempt to perform a blocked action shows a clear 'read-only' message rather than failing silently

## Notes
Protects the shared-artifact value for non-engineer audiences; access-control polish, hence P3.
