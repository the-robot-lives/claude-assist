---
id: US-461
title: "Control the lane mix ratio in the feed"
slug: control-lane-mix-ratio
personas: [P-006, P-001]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [lane, mix-ratio, personalization, feed-control]
---

# US-461: Control the Lane Mix Ratio in the Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** adjust what percentage of my feed comes from each lane
**So that** I can reduce Opposing-Views and boost Mutuals when I want a calmer experience

## Acceptance Criteria

- **Given** I open Feed Preferences
  **When** I drag sliders for Mutuals, Opposing-Views, and Discovery
  **Then** the ratios update and the feed reflects the new distribution within one refresh

- **Given** I set Opposing-Views to 0%
  **When** the feed loads
  **Then** no Opposing-Views posts appear in the home feed (they remain accessible via their dedicated lane)

- **Given** I set all non-Mutuals lanes to 0%
  **When** the feed loads
  **Then** the feed behaves equivalently to the "Mutuals only" filter

## Notes
Minimum Mutuals ratio is 50%; other lanes share the remaining 50%.
