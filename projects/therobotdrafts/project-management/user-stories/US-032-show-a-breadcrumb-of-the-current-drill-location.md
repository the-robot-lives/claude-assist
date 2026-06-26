---
id: US-032
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Show a breadcrumb of the current drill location"
epic: "Bubble navigation & orientation"
priority: P1
segment: primary
tags: [breadcrumb, drill, location, orientation]
---

# US-032 — Show a breadcrumb of the current drill location

**As** Marcus, the newly-onboarding engineer,
**I want** see a breadcrumb of where I am in the containment hierarchy,
**so that** I always know which package/class I've drilled into and can step back out.

## Acceptance criteria
- [ ] A top HUD breadcrumb shows the path (system > package > class > member) for the current drill container
- [ ] Clicking any breadcrumb segment drills back out to that level, restoring its framing
- [ ] The breadcrumb truncates long paths with an expandable middle, keeping ends visible
- [ ] At the root the breadcrumb shows the model name rather than being empty

## Notes
Implements the spec's 5.2 HUD breadcrumb; supports orientation and drill recovery for Marcus.
