---
id: US-452
title: "Browse a per-channel feed"
slug: per-channel-feed
personas: [P-002, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [feed, channel, filter]
---

# US-452: Browse a Per-Channel Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** tap any interest channel and see only posts in that channel
**So that** I can dive deep into a topic without noise from other interests

## Acceptance Criteria

- **Given** I navigate to a channel (e.g., #vintage-synths)
  **When** the channel feed loads
  **Then** only posts tagged to that channel appear, ranked by the same degree+interest+recency formula as the home feed

- **Given** I am in a channel feed
  **When** a post from a 4th-degree connection appears
  **Then** it is clearly labelled with the degree distance badge so I know it comes from outside my close network

## Notes
Channel feed respects all blocks and exclusions identically to the home feed.
