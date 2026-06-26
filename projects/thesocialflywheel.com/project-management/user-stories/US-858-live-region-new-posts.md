---
id: US-858
title: "Live Region Announcement for New Posts"
slug: live-region-new-posts
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [live-regions, screen-reader, feed, wcag-2.2]
---

# US-858: Live Region Announcement for New Posts

## User Story

**As a** screen-reader user
**I want to** be notified when new posts arrive in my feed
**So that** I can decide whether to scroll up without losing my reading position

## Acceptance Criteria

- **Given** I am reading the feed
  **When** 1–5 new posts arrive
  **Then** a polite live region announces "[N] new post(s) above. Press Home to jump to top."

- **Given** more than 5 new posts arrive in a burst
  **When** the announcement fires
  **Then** it batches them: "Several new posts above."

- **Given** I am composing a reply
  **When** new posts arrive
  **Then** the announcement is deferred until I submit or dismiss the composer

## Notes

Use aria-live="polite" to avoid interrupting in-progress announcements. Batch rapid incoming post events with a short debounce (e.g. 2 s) before updating the live region to prevent announcement floods.
