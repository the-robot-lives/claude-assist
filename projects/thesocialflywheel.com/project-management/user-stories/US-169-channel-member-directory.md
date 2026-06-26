---
id: US-169
title: "View Channel Member Directory"
slug: channel-member-directory
personas: [P-001]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, member-directory, mutuals, network]
---

# US-169: View Channel Member Directory

## User Story

**As a** Bridge-Builder
**I want to** browse the member directory of a channel filtered to members within my mutual network
**So that** I can identify which of my connections share this interest and explore potential new connections within the channel

## Acceptance Criteria

- **Given** I open the member directory of a channel I belong to
  **When** the directory loads
  **Then** members are grouped by degree of connection (1st through 4th) and non-network members, with degree badges on each avatar

- **Given** I am viewing the member directory
  **When** I tap a member's avatar
  **Then** I see their mini-profile with an option to send a mutual request if we are not yet connected

- **Given** I apply the "My Network" filter in the directory
  **When** the filter is active
  **Then** only members within my ≤4th-degree mutual graph are displayed

## Notes
Members outside the viewer's network (5th degree or no connection) are shown anonymized by default to protect privacy. The directory should not expose blocked users.
