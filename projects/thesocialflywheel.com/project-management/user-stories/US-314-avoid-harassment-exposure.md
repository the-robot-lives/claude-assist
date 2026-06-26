---
id: US-314
title: "Avoiding Harassment Exposure in Opposing-View Lane"
slug: avoid-harassment-exposure
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, harassment, safety, moderation]
---

# US-314: Avoiding Harassment Exposure in Opposing-View Lane

## User Story

**As a** cautious newcomer
**I want to** be protected from posts that are harassing or personally targeted, even if they relate to a shared interest
**So that** the Opposing-Views Lane shows genuine counter-perspectives, not attacks

## Acceptance Criteria

- **Given** a post has been flagged by the civility filter or reported multiple times
  **When** the system evaluates it for inclusion in the lane
  **Then** it is excluded until a moderator clears it

- **Given** a post directly names or references a specific user in an attacking manner
  **When** the system evaluates it
  **Then** it is automatically excluded from all users' Opposing-Views Lanes

## Notes
The harassment filter runs at ingestion time, not at display time, to avoid latency. Posts excluded by this rule should not count against the ratio.
