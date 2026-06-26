---
id: US-789
title: "Set Swipe Lane Interest Filters"
slug: set-swipe-lane-interest-filters
personas: [P-001]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [swipe, match, interests, lane-settings]
---

# US-789: Set Swipe Lane Interest Filters

## User Story

**As a** bridge-builder
**I want to** filter the Swipe-to-Match lane by specific interests
**So that** I only swipe on potential mutuals who share the topics I want to connect around

## Acceptance Criteria

- **Given** I open Settings > Swipe & Match
  **When** I select three interests as filters
  **Then** the Swipe lane shows only users who have at least one of those interests on their profile.

- **Given** I clear all swipe interest filters
  **When** I return to the Swipe lane
  **Then** the lane reverts to its default broad pool with no interest constraint applied.

## Notes
