---
id: US-190
title: "Block Cascade Applies Within Channel Context"
slug: block-cascade-in-channel
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, safety, block, cascade]
---

# US-190: Block Cascade Applies Within Channel Context

## User Story

**As a** Quiet Consumer
**I want to** have my block list automatically respected inside every channel I belong to
**So that** blocked users cannot use a shared channel as a workaround to reach me or appear in my feed

## Acceptance Criteria

- **Given** I have blocked User X on the platform
  **When** User X posts in a channel I belong to
  **Then** their post is invisible to me in all lanes of that channel without any additional configuration

- **Given** I block User X while inside a channel
  **When** the block is confirmed
  **Then** all of User X's existing posts in that channel are immediately hidden from my feed, and I cannot see them in the channel member directory

## Notes
The cascade is one-directional: a blocked user also cannot see the blocking user's posts in any channel. This mirrors the platform-wide block behavior described in the Safety epic.
