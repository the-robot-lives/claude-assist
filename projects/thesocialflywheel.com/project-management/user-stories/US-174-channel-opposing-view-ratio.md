---
id: US-174
title: "Configure Channel-Specific Opposing-View Ratio"
slug: channel-opposing-view-ratio
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, opposing-views, ratio, moderation, lanes]
---

# US-174: Configure Channel-Specific Opposing-View Ratio

## User Story

**As a** Channel Moderator
**I want to** set the maximum proportion of opposing-view content shown in my channel's Opposing-Views lane
**So that** the channel maintains its primary focus while still exposing members to constructive outside perspectives

## Acceptance Criteria

- **Given** I am in channel moderation settings
  **When** I set the opposing-view ratio to a value between 5% and 40% and save
  **Then** the Opposing-Views lane in my channel enforces that content cap, capping how much opposing content surfaces relative to total channel posts

- **Given** I leave the ratio at the default
  **When** members view the Opposing-Views lane
  **Then** the platform-default ratio (e.g., 20%) is applied

- **Given** I update the ratio
  **When** the change is saved
  **Then** a note in the channel info page reflects the current opposing-view ratio setting so members are informed

## Notes
Ratio is expressed as a percentage of total daily channel content volume. Values outside 5–40% are rejected. Changes take effect within 1 hour of saving.
