---
id: US-086
persona: P-007
persona_slug: trd-cs-educator
title: "Render monochrome-safe for projectors and handouts"
epic: "Accessibility (color/keyboard/motion)"
priority: P2
segment: tertiary
tags: [monochrome, colorblind-safe, handouts, redundancy]
---

# US-086 — Render monochrome-safe for projectors and handouts

**As** Elena, the CS educator,
**I want** render the model monochrome-safe so it reads on a bad projector or B&W handout,
**so that** every kind and edge type is distinguishable without relying on color.

## Acceptance criteria
- [ ] Monochrome mode separates all node kinds by silhouette/shape and label alone
- [ ] Edge types remain distinguishable by line style and arrowhead without color
- [ ] The mode applies consistently to on-screen, projected, and exported output
- [ ] No distinction in monochrome mode depends solely on hue (redundancy contract upheld)

## Notes
Implements authoring-ux 5.3 monochrome mode; serves Elena's monochrome-safe value and overlaps Theo (US-097).
