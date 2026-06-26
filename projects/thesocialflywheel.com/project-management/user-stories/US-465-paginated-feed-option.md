---
id: US-465
title: "Use paginated feed instead of infinite scroll"
slug: paginated-feed-option
personas: [P-008, P-006]
epic: "Feed & Ranking"
priority: could-have
complexity: medium
tags: [pagination, accessibility, feed, preference]
---

# US-465: Use Paginated Feed Instead of Infinite Scroll

## User Story

**As an** accessibility-first user (P-008)
**I want to** opt into paginated navigation (Previous / Next page buttons) instead of infinite scroll
**So that** I can maintain a predictable scroll position and use assistive technology without losing context

## Acceptance Criteria

- **Given** I enable "Paginated feed" in Accessibility Settings
  **When** I view the home feed
  **Then** posts are grouped into discrete pages with explicit Previous/Next controls at top and bottom

- **Given** paginated mode is active
  **When** I navigate to the next page
  **Then** the page scrolls to the top automatically and my focus is set to the first post

## Notes
Paginated mode also disables the floating new-post badge; instead a count appears in the page header.
