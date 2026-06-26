---
id: US-463
title: "See a new-post indicator while browsing"
slug: new-post-indicator
personas: [P-003, P-006]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [indicator, new-posts, feed, real-time]
---

# US-463: See a New-Post Indicator While Browsing

## User Story

**As a** social connector (P-003)
**I want to** see a floating badge showing "X new posts" when new content arrives while I'm mid-scroll
**So that** I can choose when to jump to new posts without losing my reading position

## Acceptance Criteria

- **Given** I am scrolled down in the feed and new posts arrive
  **When** 1 or more new posts are available above my current position
  **Then** a sticky badge appears at the top of the screen showing the count (e.g., "5 new posts ↑")

- **Given** the new-post badge is visible
  **When** I tap it
  **Then** the feed scrolls to the top and the new posts are inserted

- **Given** the new-post badge is visible
  **When** I ignore it and continue scrolling down
  **Then** the badge persists until I tap it or manually pull to refresh

## Notes
Badge count caps at "99+" for large bursts.
