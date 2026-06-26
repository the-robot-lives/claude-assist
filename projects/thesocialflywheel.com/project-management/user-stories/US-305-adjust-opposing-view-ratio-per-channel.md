---
id: US-305
title: "Adjust Opposing-View Ratio Per Channel"
slug: adjust-opposing-view-ratio-per-channel
personas: [P-001]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, ratio, channel, settings]
---

# US-305: Adjust Opposing-View Ratio Per Channel

## User Story

**As a** bridge-builder
**I want to** override the global opposing-view ratio for individual channels
**So that** I can handle politically sensitive channels differently from hobby channels

## Acceptance Criteria

- **Given** I am in a channel's settings
  **When** I set a channel-specific opposing-view ratio
  **Then** that ratio applies only in this channel and the global setting is unchanged

- **Given** I have a channel-specific ratio set
  **When** I remove the channel override
  **Then** the channel reverts to my global ratio

## Notes
Channel-level override takes precedence over global setting. UI should surface the global value as the default starting point when opening the per-channel slider.
