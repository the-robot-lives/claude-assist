---
id: US-231
title: "Block with Outer-Degree Cascade"
slug: block-with-outer-degree-cascade
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: high
tags: [safety, block, graph]
---

# US-231: Block with Outer-Degree Cascade

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** block a user with the option to cascade the block to hide content from their outer-degree network
**So that** I can create stronger separation from someone who has made me uncomfortable

## Acceptance Criteria

- **Given** I block a user
  **When** a confirmation dialog appears
  **Then** it offers an optional toggle: "Also hide content from users reachable only through [name]" (outer-degree cascade)

- **Given** I enable the cascade option
  **When** the block is confirmed
  **Then** users who were reachable to me only via the blocked person are removed from my feed, and the blocked user's posts do not appear in any lane

- **Given** I choose to block without cascade
  **When** the block is applied
  **Then** only the blocked user's content is hidden; other users reachable through them remain in my web at their existing degrees

## Notes
Cascade never severs existing direct (1st-degree) mutuals I have with third parties — it only removes the blocked user as a routing hop. See US-232.
