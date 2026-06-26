---
id: US-474
title: "Catch up on posts since last visit"
slug: catch-up-since-last-visit
personas: [P-006, P-003]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [catch-up, last-visit, feed, history]
---

# US-474: Catch Up on Posts Since Last Visit

## User Story

**As a** quiet consumer (P-006)
**I want to** tap a "Catch up from last visit" option when I open the feed
**So that** I can see everything I missed since I was last active without re-reading what I already saw

## Acceptance Criteria

- **Given** my last visit was more than 4 hours ago
  **When** I open the home feed
  **Then** a "Catch up from [time of last visit]" banner appears at the top of the feed

- **Given** I tap the catch-up banner
  **When** the feed reloads
  **Then** only posts published after my last visit timestamp are shown, in reverse-chronological order

- **Given** I finish the catch-up view
  **When** I dismiss it
  **Then** the feed returns to the standard ranked blend

## Notes
Last visit timestamp is device-stored and synced to the server on session close.
