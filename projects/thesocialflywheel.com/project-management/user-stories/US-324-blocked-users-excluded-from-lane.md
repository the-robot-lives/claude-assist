---
id: US-324
title: "Blocked Users Never Appear in Opposing-View Lane"
slug: blocked-users-excluded-from-lane
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, blocks, safety, enforcement]
---

# US-324: Blocked Users Never Appear in Opposing-View Lane

## User Story

**As a** cautious newcomer
**I want to** confirm that users I have blocked cannot appear in my Opposing-Views Lane under any circumstance
**So that** blocking is a reliable safety mechanism I can trust completely

## Acceptance Criteria

- **Given** I have blocked user U
  **When** the lane-population algorithm runs
  **Then** U is excluded from candidate selection before any interest or topic matching occurs

- **Given** user U is unblocked
  **When** the lane is next populated
  **Then** U's posts may now qualify for the lane based on normal criteria

## Notes
Block enforcement must occur at the candidate-selection layer, not at render time, to prevent timing gaps where a blocked user's post could briefly appear.
