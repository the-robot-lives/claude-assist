---
id: US-021
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Prompt the first element on an empty canvas"
epic: "Onboarding & first-run"
priority: P1
segment: primary
tags: [empty-state, ghost-prompt, first-element, onboarding]
---

# US-021 — Prompt the first element on an empty canvas

**As** Marcus, the newly-onboarding engineer,
**I want** see a ghost '+' prompt that says 'Add your first element' when the model is empty,
**so that** a blank canvas tells me the one move to make instead of leaving me staring at black space.

## Acceptance criteria
- [ ] A truly empty model shows a persistent center-world ghost '+' with 'Add your first element'
- [ ] Activating it begins add-node, placing a root container per the notation
- [ ] The prompt is persistent, not a transient flash that disappears before it's read
- [ ] Once any element exists the prompt is gone and does not flicker back on selection changes

## Notes
Implements authoring-ux 3.4 and UX-review P1-6; the empty-state must teach the first move.
