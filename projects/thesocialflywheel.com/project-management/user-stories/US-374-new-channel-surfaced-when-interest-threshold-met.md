---
id: US-374
title: "New Channel Surfaced When Interest Threshold Met"
slug: new-channel-surfaced-when-interest-threshold-met
personas: [P-002]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, channels, thresholds]
---

# US-374: New Channel Surfaced When Interest Threshold Met

## User Story

**As a** Niche Enthusiast
**I want to** be shown a new channel suggestion only after I have demonstrated consistent engagement with its topic area
**So that** channel suggestions feel earned and relevant rather than premature

## Acceptance Criteria

- **Given** I have liked or engaged with at least five discovery posts in a given topic cluster
  **When** the engine evaluates channel suggestions
  **Then** it presents a channel card for the most relevant channel in that topic cluster

- **Given** a channel card is surfaced
  **When** I dismiss it without joining
  **Then** the same channel is not re-surfaced for at least 14 days

## Notes
Threshold of five engagements is a starting value; it should be configurable via feature flag for A/B testing.
