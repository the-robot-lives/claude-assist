---
id: US-910
title: "Optimistic UI for Likes and Follows"
slug: optimistic-ui-updates
personas: [P-003]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [optimistic-ui, perceived-performance, likes, follows]
---

# US-910: Optimistic UI for Likes and Follows

## User Story

**As a** social connector who interacts rapidly with many posts
**I want to** see my likes and follows reflected instantly in the UI
**So that** the app feels responsive even when the server round-trip is slow

## Acceptance Criteria

- **Given** I tap the Like button on a post
  **When** the tap registers
  **Then** the like count increments and the button activates immediately, before the API response

- **Given** the API call for a like fails
  **When** the error is received
  **Then** the like is silently rolled back, the button reverts, and a brief error toast appears

## Notes
Track pending mutations in client state. All optimistic writes must be idempotent. Rollback must not cause visible flicker on the success path.
