---
id: US-285
title: "Swipe Card Post Count Indicator"
slug: swipe-card-post-count-indicator
personas: [P-006]
epic: "Swipe-to-Match"
priority: could-have
complexity: low
tags: [card-layout, activity, transparency]
---

# US-285: Swipe Card Post Count Indicator

## User Story

**As a** Quiet Consumer (P-006)
**I want to** see how prolific a candidate is as a poster on their swipe card
**So that** I can choose whether I want a high-volume or low-volume contributor in my feed

## Acceptance Criteria

- **Given** a candidate has a post history
  **When** their card is shown
  **Then** a compact indicator shows their average weekly post count (e.g., "~3 posts/week")

- **Given** a candidate has fewer than 5 total posts
  **When** their card is shown
  **Then** the indicator reads "New to posting" instead of a rate
