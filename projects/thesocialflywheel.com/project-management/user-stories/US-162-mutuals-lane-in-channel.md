---
id: US-162
title: "View Mutuals Lane Within a Channel"
slug: mutuals-lane-in-channel
personas: [P-001]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, lanes, mutuals, feed]
---

# US-162: View Mutuals Lane Within a Channel

## User Story

**As a** Bridge-Builder
**I want to** view a Mutuals-only lane inside a channel showing posts from people I have a symmetric mutual connection with
**So that** I can engage in full two-way conversation with people I already trust within this interest space

## Acceptance Criteria

- **Given** I am inside a channel and I have mutual connections who are also channel members
  **When** I switch to the Mutuals lane
  **Then** I see posts only from members who are confirmed mutuals (≤4th-degree symmetric graph) and can reply, react, and interact fully

- **Given** I switch to the Mutuals lane
  **When** none of my mutuals are channel members
  **Then** I see an empty state explaining this lane is available once mutuals join the channel, with a share option

## Notes
Mutuals lane allows full bidirectional interaction. All three lanes (Mutuals, Swipe-to-Match, Opposing-Views) are accessible via a tab or toggle at the top of the channel feed.
