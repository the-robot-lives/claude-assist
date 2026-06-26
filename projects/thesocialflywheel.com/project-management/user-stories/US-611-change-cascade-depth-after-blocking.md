---
id: US-611
title: "Change Cascade Depth After Blocking"
slug: change-cascade-depth-after-blocking
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: medium
tags: [safety, blocking, cascade]
---

# US-611: Change Cascade Depth After Blocking

## User Story

**As a** bridge-builder
**I want to** adjust the cascade depth of an existing block after I have set it
**So that** I can tighten or loosen network-level protection without having to unblock and re-block

## Acceptance Criteria

- **Given** I have an active direct-only block on User X
  **When** I open the block detail in Settings and toggle cascade on
  **Then** the block immediately applies to the outer-degree network

- **Given** I have an active cascade block on User X
  **When** I switch it back to direct-only
  **Then** content from User X's mutuals-of-mutuals becomes visible again

## Notes
Cascade changes take effect within one feed refresh cycle.
