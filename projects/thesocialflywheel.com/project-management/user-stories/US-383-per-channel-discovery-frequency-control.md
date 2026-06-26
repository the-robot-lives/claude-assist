---
id: US-383
title: "Per-Channel Discovery Frequency Control"
slug: per-channel-discovery-frequency-control
personas: [P-002]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, channels, settings]
---

# US-383: Per-Channel Discovery Frequency Control

## User Story

**As a** Niche Enthusiast
**I want to** set how often discovery content from a specific channel appears in my feed
**So that** I can amplify channels I am curious about and quiet ones I have already explored

## Acceptance Criteria

- **Given** I tap on a channel card in the discovery feed
  **When** I open channel options
  **Then** I see a frequency selector with options: More, Normal, Less, None

- **Given** I set a channel's discovery frequency to "More"
  **When** the engine allocates discovery slots
  **Then** that channel's content receives a proportionally higher share of discovery slots compared to other channels

## Notes
Per-channel settings override the global volume slider for that specific channel only.
