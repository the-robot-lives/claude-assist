---
id: US-031
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Show a persistent verb rail of available actions"
epic: "Authoring (add/connect/edit/re-parent)"
priority: P0
segment: primary
tags: [verb-rail, toolbar, discoverability, command-surface]
---

# US-031 — Show a persistent verb rail of available actions

**As** Marcus, the newly-onboarding engineer,
**I want** see a slim left rail with Select, Add, Connect, Delete, Undo, Redo, and Project,
**so that** I can see what I can do instead of discovering verbs by right-clicking.

## Acceptance criteria
- [ ] A vertical left rail renders the authoring verbs with 32px hit targets and labeled glyphs
- [ ] The active mode shows the reserved white->cyan active pill; Undo/Redo dim when history is empty
- [ ] Project is disabled until a region is selected, with a tooltip explaining why
- [ ] Hovering any rail button shows its tooltip and hotkey

## Notes
Implements authoring-ux 2.2 and UX-review A1; the spec's verb rail was never built (P0-1).
