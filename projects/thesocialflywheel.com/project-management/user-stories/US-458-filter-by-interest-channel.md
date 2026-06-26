---
id: US-458
title: "Filter feed by a specific interest channel"
slug: filter-by-interest-channel
personas: [P-002, P-006]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [filter, channel, interest, feed-control]
---

# US-458: Filter Feed by a Specific Interest Channel

## User Story

**As a** quiet consumer (P-006)
**I want to** filter my home feed to show only posts from a chosen channel
**So that** I can binge a single topic without navigating away to the channel view

## Acceptance Criteria

- **Given** I open the feed filter panel
  **When** I select a channel from my subscriptions list
  **Then** the home feed immediately shows only posts tagged to that channel, across all degrees

- **Given** a channel filter is active
  **When** I clear the filter
  **Then** the full blended feed returns

## Notes
Multiple channels can be selected simultaneously (OR logic).
