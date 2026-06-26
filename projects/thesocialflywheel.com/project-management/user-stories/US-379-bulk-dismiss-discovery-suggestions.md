---
id: US-379
title: "Bulk Dismiss Discovery Suggestions"
slug: bulk-dismiss-discovery-suggestions
personas: [P-006]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, controls, bulk]
---

# US-379: Bulk Dismiss Discovery Suggestions

## User Story

**As a** Quiet Consumer
**I want to** bulk-dismiss all pending discovery items in my current feed session
**So that** I can quickly clear discovery content when I only want to see my mutuals' posts

## Acceptance Criteria

- **Given** there are discovery items in my current feed session
  **When** I tap "Clear all discovery" from the feed options menu
  **Then** all discovery items are removed from the current session without sending any like or dislike signals

- **Given** I bulk-dismiss discovery items
  **When** I pull to refresh the feed
  **Then** new discovery items may reappear at normal cadence since no signals were recorded

## Notes
Bulk dismiss is purely a session-level UI action and has no effect on the topic model or exclusion list.
