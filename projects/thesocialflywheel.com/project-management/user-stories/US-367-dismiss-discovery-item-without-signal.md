---
id: US-367
title: "Dismiss Discovery Item Without Signal"
slug: dismiss-discovery-item-without-signal
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, feed, controls]
---

# US-367: Dismiss Discovery Item Without Signal

## User Story

**As a** Quiet Consumer
**I want to** dismiss a discovery item from my feed without sending a like or dislike signal
**So that** I can clean up my feed without affecting the discovery engine's topic model

## Acceptance Criteria

- **Given** a discovery item is visible in my feed
  **When** I swipe or tap the dismiss action on the item
  **Then** the item is removed from the current feed session and does not reappear in the same session

- **Given** I dismiss a discovery item without signaling
  **When** the next feed session loads
  **Then** the dismissed item may reappear as normal since no negative signal was recorded

## Notes
Dismiss is a UI convenience action. It is neutral and does not affect ranking or topic weighting.
