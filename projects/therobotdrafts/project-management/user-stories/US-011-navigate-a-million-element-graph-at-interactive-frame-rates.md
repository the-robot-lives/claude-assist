---
id: US-011
persona: P-001
persona_slug: trd-systems-architect
title: "Navigate a million-element graph at interactive frame rates"
epic: "Performance & scale"
priority: P1
segment: primary
tags: [performance, scale, hlod, rendering]
---

# US-011 — Navigate a million-element graph at interactive frame rates

**As** Dana, the Systems Architect,
**I want** load and fly through a graph with on the order of a million elements smoothly,
**so that** the tool actually works on my real 4M-line platform, not just toy repos.

## Acceptance criteria
- [ ] A large graph maintains an interactive frame rate while orbiting and drilling (HLOD/culling engaged)
- [ ] Off-screen and distant subtrees collapse to HLOD proxies rather than rendering every element
- [ ] Frame rate does not collapse when a dense cluster enters view; LOD degrades gracefully
- [ ] If the model exceeds a memory threshold, the tool warns and offers to stream/partition rather than crashing

## Notes
Counters Dana's frustration that legacy reverse-engineering chokes on large repos (P-001 frustration 3); rendering pipeline goal.
