---
id: US-348
title: "Ratio Persists Correctly Across Channel Switches"
slug: ratio-defaults-on-channel-switch
personas: [P-005]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, ratio, channel, persistence, settings]
---

# US-348: Ratio Persists Correctly Across Channel Switches

## User Story

**As a** debate seeker
**I want to** have my per-channel ratio override preserved when I switch between channels
**So that** I do not have to re-configure settings every time I move between channel contexts

## Acceptance Criteria

- **Given** I have set a custom ratio for channel A and a different ratio for channel B
  **When** I switch from channel A to channel B
  **Then** channel B immediately reflects its saved ratio without a reload

- **Given** I switch to a channel with no override set
  **When** the lane renders
  **Then** it uses my global ratio, not the ratio of the previously viewed channel

## Notes
Ratio state must be stored per-channel server-side, not in client session state, to persist across devices.
