---
id: US-222
title: "Unmutual Ripple on Feed"
slug: unmutual-ripple-on-feed
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: high
tags: [graph, feed, removal]
---

# US-222: Unmutual Ripple on Feed

## User Story

**As a** Social Connector (P-003)
**I want to** see my feed accurately reflect the removal of a mutual, including cascading degree changes for previously-reachable users
**So that** my feed stays consistent with my actual social graph after I unmutual someone

## Acceptance Criteria

- **Given** I unmutual someone who was a bridge to several 2nd-degree users
  **When** those users have no other 1st-degree path to me
  **Then** their degree increases (e.g., from 2nd to 3rd) or they drop out of reachability, and their posts are removed or re-filtered accordingly on next feed refresh

- **Given** the graph recalculation is in progress after an unmutual
  **When** my feed is displayed
  **Then** stale degree-based posts are not shown for longer than one feed refresh cycle (max 60 s)

## Notes
Full graph recalculation is asynchronous. A brief loading state or "Your feed is updating" banner is acceptable.
