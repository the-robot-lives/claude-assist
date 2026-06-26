---
id: US-013
persona: P-001
persona_slug: trd-systems-architect
title: "Color nodes by a structural metric to spot bottlenecks"
epic: "Search & filter"
priority: P1
segment: primary
tags: [metrics, fan-in, heatmap, analysis]
---

# US-013 — Color nodes by a structural metric to spot bottlenecks

**As** Dana, the Systems Architect,
**I want** shade nodes by a structural metric such as fan-in so hotspots stand out,
**so that** I can find the bottleneck service without reading every edge.

## Acceptance criteria
- [ ] A metric overlay (fan-in/fan-out/size) maps a value to an intensity ramp on bubbles
- [ ] The overlay uses a perceptually-ordered ramp plus a legend, and pairs intensity with a numeric badge so it survives monochrome
- [ ] The top-N nodes by the chosen metric can be listed and focused from the legend
- [ ] Turning the overlay off restores the default kind hues without reloading the model

## Notes
Serves the coupling-audit scenario (drill into the service with most inbound deps); keeps metric encoding non-color-only.
