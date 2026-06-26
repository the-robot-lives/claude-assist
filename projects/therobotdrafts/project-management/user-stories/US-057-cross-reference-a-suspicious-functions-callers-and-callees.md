---
id: US-057
persona: P-004
persona_slug: trd-reverse-engineer
title: "Cross-reference a suspicious function's callers and callees"
epic: "Bubble navigation & orientation"
priority: P0
segment: secondary
tags: [xref, callers, callees, investigation]
---

# US-057 — Cross-reference a suspicious function's callers and callees

**As** Sven, the reverse engineer,
**I want** see both the callers and callees of a suspicious function at once,
**so that** I can understand what a function touches and what reaches it in one move.

## Acceptance criteria
- [ ] Selecting a function reveals inbound (callers) and outbound (callees) edges, distinguished by direction
- [ ] Each side is listed and individually focusable
- [ ] I can expand one more hop in either direction to follow the chain
- [ ] A leaf function with no callees shows that explicitly rather than an empty outbound list

## Notes
Serves Sven goal 3 (cross-reference call paths) and his CLI-xref behavior, made spatial.
