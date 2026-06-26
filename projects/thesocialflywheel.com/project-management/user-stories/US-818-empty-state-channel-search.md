---
id: US-818
title: "Empty State for Channel Search with Guidance"
slug: empty-state-channel-search
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, empty-state, channels, UX]
---

# US-818: Empty State for Channel Search with Guidance

## User Story

**As a** accessibility-first user
**I want to** see a helpful, screen-reader-friendly empty state when channel search finds nothing
**So that** I understand what happened and know what to try next

## Acceptance Criteria

- **Given** I search channels and no results match
  **When** the results area renders
  **Then** an ARIA live region announces "No channels found for [query]" and the visible UI suggests checking spelling or browsing Discovery

- **Given** the empty state is shown
  **When** I navigate by keyboard
  **Then** all suggestion links are in the tab order and reachable without a mouse

## Notes
Empty state illustration or icon must have a meaningful alt text or be aria-hidden if decorative.
