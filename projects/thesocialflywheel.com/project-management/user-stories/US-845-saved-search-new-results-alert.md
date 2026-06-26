---
id: US-845
title: "Alert Me When a Saved Search Has New Results"
slug: saved-search-new-results-alert
personas: [P-002]
epic: "Search & Find"
priority: could-have
complexity: high
tags: [search, saved, notifications, alerts]
---

# US-845: Alert Me When a Saved Search Has New Results

## User Story

**As a** niche enthusiast
**I want to** opt into notifications when a saved search has new results
**So that** I stay on top of emerging content without manually re-running searches

## Acceptance Criteria

- **Given** I save a search with notifications enabled
  **When** new content matching the saved search appears
  **Then** I receive an in-app notification with a count of new results

- **Given** a saved search notification arrives
  **When** I click it
  **Then** the saved search opens with new results sorted to the top or visually highlighted

## Notes
Notifications are batched to at most once per hour per saved search to prevent notification fatigue.
