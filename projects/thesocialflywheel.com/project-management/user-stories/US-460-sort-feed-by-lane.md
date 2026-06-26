---
id: US-460
title: "Sort or isolate feed by lane"
slug: sort-feed-by-lane
personas: [P-005, P-001]
epic: "Feed & Ranking"
priority: could-have
complexity: medium
tags: [sort, lane, feed-control]
---

# US-460: Sort or Isolate Feed by Lane

## User Story

**As a** bridge-builder (P-001)
**I want to** view the feed filtered to a single lane (e.g., only Opposing-Views)
**So that** I can intentionally engage with each content type without them competing for attention

## Acceptance Criteria

- **Given** I open the sort/filter panel
  **When** I select "Opposing-Views only"
  **Then** the feed shows only posts from the Opposing-Views lane in recency order

- **Given** a lane filter is active
  **When** I return to the home feed tab
  **Then** the lane filter is automatically cleared and the full blended feed resumes

## Notes
Lane isolation is a temporary view mode, not a persistent preference.
