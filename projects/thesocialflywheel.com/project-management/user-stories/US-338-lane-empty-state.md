---
id: US-338
title: "Opposing-View Lane Empty State"
slug: lane-empty-state
personas: [P-001]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, empty-state, ux, feed-design]
---

# US-338: Opposing-View Lane Empty State

## User Story

**As a** bridge-builder
**I want to** see an informative empty state when no opposing-view posts qualify for my lane
**So that** I understand the silence is intentional rather than a loading error

## Acceptance Criteria

- **Given** no posts currently qualify for my Opposing-Views Lane
  **When** I view the lane
  **Then** an empty state message reads "No opposing views to show right now — come back later or broaden your interests"

- **Given** the empty state is showing
  **When** qualifying posts become available
  **Then** the lane populates on the next feed refresh without requiring a manual page reload

## Notes
Empty state should suggest actionable next steps (e.g. "Add more interests") rather than just explaining the absence.
