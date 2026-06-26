---
id: US-909
title: "Skeleton Screens During Content Loads"
slug: skeleton-screens
personas: [P-008]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [skeleton, perceived-performance, loading-states, ux]
---

# US-909: Skeleton Screens During Content Loads

## User Story

**As an** accessibility-first user who relies on predictable page structure
**I want to** see content-shaped placeholder skeletons while the feed loads
**So that** I understand the layout before data arrives and do not perceive the app as broken

## Acceptance Criteria

- **Given** I navigate to the Mutuals feed and data has not yet arrived
  **When** the page renders
  **Then** skeleton placeholders matching the post-card layout appear within 300 ms of navigation

- **Given** a skeleton is displayed
  **When** real data loads
  **Then** the transition from skeleton to content is smooth with no layout shift (CLS < 0.1)

## Notes
Skeletons must include ARIA `aria-busy="true"` on the container so screen readers announce loading state. Animate with CSS pulse, not JS.
