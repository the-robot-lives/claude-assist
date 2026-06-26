---
id: US-002
persona: P-001
persona_slug: trd-systems-architect
title: "Frame the whole-system overview"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [navigation, overview, frame-all, orientation]
---

# US-002 — Frame the whole-system overview

**As** Dana, the Systems Architect,
**I want** frame the entire system in one view to see its major clusters before drilling in,
**so that** I can orient myself on an unfamiliar 4M-line platform without getting lost.

## Acceptance criteria
- [ ] A single command (Ctrl/Cmd+F 'frame all') fits every top-level bubble in view with margin
- [ ] Top-level package/service clusters are visually separated and individually labeled
- [ ] Labels at the overview LOD remain legible (name-only billboard or larger card), not unreadable pinpricks
- [ ] On an empty model the frame command is a no-op that surfaces the empty-state prompt instead of flying into black space

## Notes
Counters UX-review P0-3 (lost-in-space) and P0-4 (label legibility) for the architect's first orientation pass.
