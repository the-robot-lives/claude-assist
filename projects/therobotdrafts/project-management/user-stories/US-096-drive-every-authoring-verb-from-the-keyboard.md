---
id: US-096
persona: P-009
persona_slug: trd-accessibility-first-dev
title: "Drive every authoring verb from the keyboard"
epic: "Accessibility (color/keyboard/motion)"
priority: P0
segment: edge-case
tags: [keyboard, authoring, no-mouse, accessibility]
---

# US-096 — Drive every authoring verb from the keyboard

**As** Theo, the accessibility-constrained developer,
**I want** perform every authoring verb - add, connect, edit, re-parent, delete, project - from the keyboard,
**so that** my disability doesn't lock me out of features that assume a mouse or hover.

## Acceptance criteria
- [ ] Add, connect, edit/rename, re-parent, delete, undo/redo, and project are all reachable by keyboard with discoverable shortcuts
- [ ] Keyboard focus can traverse nodes/edges and select targets without a mouse or hover
- [ ] A connect can be completed by keyboard (pick source, pick target) without a drag gesture
- [ ] Every keyboard action gives non-visual-only confirmation (status text/announcement), not just a transient cursor change

## Notes
Counters Theo's frustration 3 (mouse/hover-only UIs lock him out); serves goal 2 (drive everything by keyboard).
