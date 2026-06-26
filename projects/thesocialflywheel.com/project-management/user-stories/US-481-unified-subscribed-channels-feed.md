---
id: US-481
title: "See a unified feed across all subscribed channels"
slug: unified-subscribed-channels-feed
personas: [P-002, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [channel, subscription, feed, unified]
---

# US-481: See a Unified Feed Across All Subscribed Channels

## User Story

**As a** niche enthusiast (P-002)
**I want to** see a single feed that merges posts from all my subscribed channels
**So that** I don't have to visit each channel individually to stay current

## Acceptance Criteria

- **Given** I subscribe to 5 channels
  **When** I view the home feed
  **Then** posts from all 5 channels are merged and ranked together by degree+interest+recency

- **Given** one channel is significantly more active than others
  **When** the feed loads
  **Then** posts from that channel are not permitted to dominate more than 40% of the visible feed slots (per-channel cap)

## Notes
Per-channel cap prevents a single firehose channel from crowding out niche subscriptions.
