---
id: US-487
title: "Resume feed at my last read position"
slug: feed-read-position-sync
personas: [P-006, P-003]
epic: "Feed & Ranking"
priority: could-have
complexity: medium
tags: [read-position, sync, catch-up, feed]
---

# US-487: Resume Feed at My Last Read Position

## User Story

**As a** quiet consumer (P-006)
**I want to** return to where I left off in the feed after closing the app
**So that** I don't lose my scroll position between sessions

## Acceptance Criteria

- **Given** I close the app while scrolled midway through the feed
  **When** I reopen the app within 4 hours
  **Then** the feed restores my last position with a "You left off here" divider

- **Given** more than 4 hours have passed since my last visit
  **When** I open the app
  **Then** the feed loads fresh from the top with the catch-up banner (see US-474) instead of restoring position

## Notes
Position sync is device-local; no cross-device sync in V1.
