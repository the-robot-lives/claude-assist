---
id: US-034
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Read a class's members in a detail panel"
epic: "Bubble navigation & orientation"
priority: P1
segment: primary
tags: [detail-panel, members, inspector, comprehension]
---

# US-034 — Read a class's members in a detail panel

**As** Marcus, the newly-onboarding engineer,
**I want** open a detail panel that lists a selected class's fields and methods with signatures,
**so that** I can understand a class without drilling into every member bubble.

## Acceptance criteria
- [ ] Selecting a class shows a panel with its members, signatures, and visibility notation
- [ ] Members in the panel are selectable and focus the corresponding bubble
- [ ] The panel shows doc-comments where present
- [ ] A class with no members shows an explicit empty state, not a blank panel

## Notes
Aids code comprehension (Marcus goal 1) using the build's existing rich per-member UML data.
