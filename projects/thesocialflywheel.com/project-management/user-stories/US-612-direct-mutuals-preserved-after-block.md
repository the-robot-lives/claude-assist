---
id: US-612
title: "Direct Mutuals Preserved After Block"
slug: direct-mutuals-preserved-after-block
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, blocking, mutuals]
---

# US-612: Direct Mutuals Preserved After Block

## User Story

**As a** cautious newcomer
**I want to** be assured that blocking someone does not sever my connections to my own direct mutuals who also know them
**So that** I retain my existing relationships even when using cascade blocking

## Acceptance Criteria

- **Given** I block User X with cascade enabled
  **When** I view my Mutuals lane
  **Then** friends who are also mutuals of User X remain in my Mutuals lane

- **Given** cascade block is active
  **When** a direct mutual of mine who is also mutual of X posts in my Mutuals lane
  **Then** their post is visible to me as normal

## Notes
The block only affects content routed through the blocked person's graph node; direct relationships are a separate edge.
