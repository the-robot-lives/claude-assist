---
id: US-164
title: "Read Opposing-Views Lane Within a Channel"
slug: opposing-views-lane-in-channel
personas: [P-001]
epic: "Interest Channels"
priority: must-have
complexity: high
tags: [channels, lanes, opposing-views, read-only, ratio]
---

# US-164: Read Opposing-Views Lane Within a Channel

## User Story

**As a** Bridge-Builder
**I want to** read posts in the Opposing-Views lane of a channel that surface perspectives from adjacent or contrasting interest clusters
**So that** I can broaden my understanding without the channel becoming dominated by dissenting content

## Acceptance Criteria

- **Given** I am in the Opposing-Views lane of a channel
  **When** I view posts
  **Then** the posts are read-only — I cannot reply, react, or interact — and the lane is visually distinguished from the Mutuals and Swipe-to-Match lanes

- **Given** the channel has a configured opposing-view ratio
  **When** the Opposing-Views lane is populated
  **Then** the volume of opposing-view content does not exceed the ratio set by the channel moderator (e.g., 20% of total channel posts)

- **Given** I am in the Opposing-Views lane
  **When** a post author is someone I have blocked
  **Then** their posts are excluded from my view of this lane

## Notes
The fixed ratio enforced here is the channel-level ratio, which overrides the platform default when set. See US-169 for moderator configuration of this ratio.
