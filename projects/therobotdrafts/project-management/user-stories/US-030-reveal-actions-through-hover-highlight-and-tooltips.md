---
id: US-030
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Reveal actions through hover highlight and tooltips"
epic: "Authoring (add/connect/edit/re-parent)"
priority: P0
segment: primary
tags: [hover, tooltips, feedback, discoverability]
---

# US-030 — Reveal actions through hover highlight and tooltips

**As** Marcus, the newly-onboarding engineer,
**I want** see nodes highlight on hover and get tooltips with hotkeys on every control,
**so that** I can learn what's clickable and what each verb does without opening Help.

## Acceptance criteria
- [ ] Hovering a node lifts its emissive/highlight so hit targets are obvious
- [ ] Every toolbar/verb control shows a tooltip naming the action and its hotkey (e.g. 'Connect - C / drag from rim')
- [ ] Tooltips appear after a short, consistent delay and dismiss on move-away
- [ ] Hover affordances never obscure the node label or the thing being hovered

## Notes
Implements UX-review A2 and B7; counters P0-5 (no hover feedback) and P0-2 (no tooltips).
