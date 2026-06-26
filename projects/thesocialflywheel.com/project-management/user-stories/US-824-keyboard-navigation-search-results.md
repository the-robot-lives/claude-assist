---
id: US-824
title: "Keyboard Navigation Through Search Results"
slug: keyboard-navigation-search-results
personas: [P-008]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, keyboard, accessibility, navigation]
---

# US-824: Keyboard Navigation Through Search Results

## User Story

**As a** accessibility-first user
**I want to** navigate all search results and controls using only the keyboard
**So that** I can use the search feature without a mouse

## Acceptance Criteria

- **Given** search results are visible
  **When** I press Tab
  **Then** focus moves through each result card and interactive control in a logical document order

- **Given** I focus a result card
  **When** I press Enter
  **Then** I navigate to the destination (channel, profile, or post) as expected

## Notes
Focus ring must always be visible; the design system's default outline must not be suppressed.
