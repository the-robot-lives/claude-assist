---
id: US-283
title: "Focus Management in Swipe UI"
slug: focus-management-in-swipe-ui
personas: [P-008]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [accessibility, focus-management, a11y, keyboard]
---

# US-283: Focus Management in Swipe UI

## User Story

**As an** Accessibility-First user (P-008)
**I want to** have keyboard focus automatically move to the next card after I act on the current one
**So that** I can swipe through the queue without losing my place or tabbing back from the top of the page

## Acceptance Criteria

- **Given** I action a swipe card via keyboard
  **When** the next card slides in
  **Then** focus is programmatically set to the new card's primary interactive element

- **Given** the swipe queue is empty after I act on the last card
  **When** the empty state renders
  **Then** focus moves to the empty-state heading so screen readers announce it immediately
