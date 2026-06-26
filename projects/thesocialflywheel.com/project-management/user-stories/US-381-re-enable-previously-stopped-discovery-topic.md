---
id: US-381
title: "Re-Enable Previously Stopped Discovery Topic"
slug: re-enable-previously-stopped-discovery-topic
personas: [P-002]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, tuning, controls]
---

# US-381: Re-Enable Previously Stopped Discovery Topic

## User Story

**As a** Niche Enthusiast
**I want to** restore a topic I previously excluded from discovery
**So that** I can change my mind after time has passed and re-engage with that topic area

## Acceptance Criteria

- **Given** I navigate to Discovery Settings and view my excluded topics list
  **When** I tap "Re-enable" on a previously excluded topic
  **Then** the topic is removed from the exclusion list and becomes eligible for the next rotation cycle

- **Given** I re-enable a topic
  **When** the current rotation is active and the topic was scheduled for this period
  **Then** the topic begins appearing in discovery within the next feed refresh

## Notes
Re-enabled topics start with a neutral weight, not their previously accumulated positive or negative weights.
