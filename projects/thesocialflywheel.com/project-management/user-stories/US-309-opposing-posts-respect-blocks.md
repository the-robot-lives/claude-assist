---
id: US-309
title: "Opposing Posts Respect User Blocks"
slug: opposing-posts-respect-blocks
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, blocks, safety, privacy]
---

# US-309: Opposing Posts Respect User Blocks

## User Story

**As a** cautious newcomer
**I want to** be certain that blocking a user prevents their posts from appearing in my Opposing-Views Lane
**So that** my block decisions are consistently enforced across every part of the product

## Acceptance Criteria

- **Given** I have blocked user U
  **When** the Opposing-Views Lane is populated
  **Then** no posts authored by U appear in the lane, even if U's views would otherwise qualify

- **Given** user U has blocked me
  **When** the Opposing-Views Lane is populated for other users
  **Then** my posts do not appear in U's lane

## Notes
Block enforcement must be bidirectional. This applies to both direct blocks and blocks inherited from channel-level ban actions.
