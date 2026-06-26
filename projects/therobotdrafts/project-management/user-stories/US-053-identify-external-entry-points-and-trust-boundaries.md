---
id: US-053
persona: P-004
persona_slug: trd-reverse-engineer
title: "Identify external entry points and trust boundaries"
epic: "Search & filter"
priority: P1
segment: secondary
tags: [trust-boundaries, entry-points, attack-surface, analysis]
---

# US-053 — Identify external entry points and trust boundaries

**As** Sven, the reverse engineer,
**I want** highlight the external entry points and trust boundaries of a source-less dependency,
**so that** I can find the attack surface quickly.

## Acceptance criteria
- [ ] An analysis flags public/exported entry points and external-facing interfaces
- [ ] Trust boundaries (external vs internal, native vs managed) are visually delineated with shape+label, not color alone
- [ ] Entry points are listed and focusable
- [ ] A dependency with no external entry points is reported as such rather than showing an empty result

## Notes
Serves Sven goal 2 (find attack surface and trust boundaries); uses redundancy-contract encoding.
