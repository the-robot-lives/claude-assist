---
id: US-489
title: "See new post count on the feed tab icon"
slug: new-post-count-tab-badge
personas: [P-003, P-009]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [badge, count, notification, feed-tab]
---

# US-489: See New Post Count on the Feed Tab Icon

## User Story

**As a** social connector (P-003)
**I want to** see an unread-post count badge on the feed tab icon
**So that** I know at a glance when new content is waiting without opening the feed

## Acceptance Criteria

- **Given** new posts arrive from my mutuals while I am on a different tab
  **When** the background sync completes
  **Then** the feed tab icon shows a badge with the unread count (capped at 99+)

- **Given** I open the feed and scroll to the top
  **When** I have viewed the new-post indicator or pulled to refresh
  **Then** the tab badge clears to zero

- **Given** I disable notification badges in app settings
  **When** new posts arrive
  **Then** no badge appears on the feed tab icon

## Notes
Badge count reflects new posts from mutuals only, not 2nd–4th degree or Discovery.
