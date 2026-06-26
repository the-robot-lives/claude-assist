---
id: US-187
title: "View Channel Activity Feed"
slug: channel-activity-feed
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, feed, activity, consumption]
---

# US-187: View Channel Activity Feed

## User Story

**As a** Quiet Consumer
**I want to** view a chronological and relevance-ranked feed of posts within a channel
**So that** I can catch up on what the community is discussing without missing important or high-engagement content

## Acceptance Criteria

- **Given** I open a channel I belong to
  **When** the feed loads
  **Then** I see posts in a mixed ranking of recency and engagement (likes, replies) within the active lane, with timestamps visible on every post

- **Given** I have been away from a channel for more than 24 hours
  **When** I return and open it
  **Then** a "You were away" divider marks where I left off, and I can jump to the newest posts via a floating "Jump to Latest" button

## Notes
Feed should load within 1 second on a standard connection. Infinite scroll is preferred over pagination. Posts from blocked users are silently omitted.
