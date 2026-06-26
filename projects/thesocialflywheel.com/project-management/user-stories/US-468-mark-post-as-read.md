---
id: US-468
title: "Mark a post as read to clear it from feed"
slug: mark-post-as-read
personas: [P-006, P-003]
epic: "Feed & Ranking"
priority: could-have
complexity: low
tags: [mark-read, feed, read-state]
---

# US-468: Mark a Post as Read to Clear It from Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** mark posts as read so they don't reappear on subsequent feed loads
**So that** each feed session feels fresh and I don't re-read the same content

## Acceptance Criteria

- **Given** I have scrolled past a post (it was in the viewport for ≥2 seconds)
  **When** I return to the top of the feed or refresh
  **Then** previously viewed posts are visually dimmed or de-prioritised in the ranking

- **Given** I explicitly tap "Mark as read" on a post
  **When** the feed refreshes
  **Then** that post does not reappear for 48 hours unless I explicitly search for it

## Notes
Auto-read detection (viewport dwell) is opt-in via Feed Preferences.
