---
id: US-358
title: "Blocked Users Excluded from Discovery"
slug: blocked-users-excluded-from-discovery
personas: [P-005]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, safety, blocking]
---

# US-358: Blocked Users Excluded from Discovery

## User Story

**As a** Debate Seeker
**I want to** ensure content authored by users I have blocked never appears in my discovery feed
**So that** my block list is respected across all surfaces, not just the direct social graph

## Acceptance Criteria

- **Given** I have blocked user A
  **When** the discovery engine selects items for my feed
  **Then** no content authored or reshared by user A is included regardless of degree of connection

- **Given** I block a user while a discovery item from them is already rendered in my feed
  **When** I complete the block action
  **Then** the discovery item from that user is removed from the current feed session immediately

## Notes
Block exclusion must propagate to discovery within the same request cycle, not asynchronously.
