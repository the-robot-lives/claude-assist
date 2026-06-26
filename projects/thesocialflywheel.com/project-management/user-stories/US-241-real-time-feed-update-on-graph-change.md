---
id: US-241
title: "Real-Time Feed Update on Graph Change"
slug: real-time-feed-update-on-graph-change
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: high
tags: [feed, graph, real-time]
---

# US-241: Real-Time Feed Update on Graph Change

## User Story

**As a** Social Connector (P-003)
**I want to** see my feed update promptly after any graph change (new mutual, unmutual, block)
**So that** the feed always reflects my current social graph without requiring a manual app restart

## Acceptance Criteria

- **Given** I accept a mutual request while the app is in the foreground
  **When** the connection is established
  **Then** the new mutual's posts begin appearing in my feed within 60 seconds without a manual refresh

- **Given** I unmutual someone while the app is in the foreground
  **When** the disconnection is processed
  **Then** their previously unfiltered posts are removed or re-ranked within one feed refresh cycle (≤ 60 s)

- **Given** a graph change occurs while the app is in the background
  **When** I re-open the app
  **Then** the feed reflects the updated graph state on the first load

## Notes
Full graph recalculation may be async; a "Feed updated" toast is acceptable to signal the change has been applied.
