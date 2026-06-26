---
id: US-028
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Distinguish core modules from peripheral ones"
epic: "Search & filter"
priority: P1
segment: primary
tags: [centrality, core-vs-peripheral, overlay, comprehension]
---

# US-028 — Distinguish core modules from peripheral ones

**As** Marcus, the newly-onboarding engineer,
**I want** see at a glance which modules are central/core and which are peripheral,
**so that** I can tell what matters most in a system I don't know yet.

## Acceptance criteria
- [ ] A centrality overlay sizes or shades nodes by connectedness with a legend
- [ ] Core (high-centrality) nodes are also labeled/badged so the distinction isn't color-only
- [ ] I can list the top core modules and focus them from the overlay
- [ ] Toggling the overlay off restores the default view without re-import

## Notes
Counters Marcus's frustration 3 (can't tell core from peripheral); non-color-only per redundancy contract.
