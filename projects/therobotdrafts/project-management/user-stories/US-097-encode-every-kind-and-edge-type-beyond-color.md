---
id: US-097
persona: P-009
persona_slug: trd-accessibility-first-dev
title: "Encode every kind and edge type beyond color"
epic: "Accessibility (color/keyboard/motion)"
priority: P0
segment: edge-case
tags: [monochrome, shape, redundancy, colorblind]
---

# US-097 — Encode every kind and edge type beyond color

**As** Theo, the accessibility-constrained developer,
**I want** have every node kind and edge type distinguishable by shape and label, not just hue,
**so that** as a colorblind user I can tell every distinction apart.

## Acceptance criteria
- [ ] Each of the nine node kinds is separable by silhouette/shape and text label alone (monochrome passes)
- [ ] Each edge type is separable by line style and arrowhead/decoration without color
- [ ] A monochrome mode lets me verify no distinction is color-only
- [ ] The reserved UI-state channel uses shape cues (dashed rim + checkmark/cross), not color alone, for valid/invalid

## Notes
Implements the redundancy contract (authoring-ux 5.2) and Theo's grayscale-check scenario (P-009 scenario 1).
