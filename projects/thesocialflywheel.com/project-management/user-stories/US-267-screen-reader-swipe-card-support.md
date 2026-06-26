---
id: US-267
title: "Screen Reader Swipe Card Support"
slug: screen-reader-swipe-card-support
personas: [P-008]
epic: "Swipe-to-Match"
priority: must-have
complexity: high
tags: [accessibility, screen-reader, a11y, WCAG]
---

# US-267: Screen Reader Swipe Card Support

## User Story

**As an** Accessibility-First user (P-008)
**I want to** have swipe cards fully announced by my screen reader
**So that** I can evaluate candidates and take action without relying on visual presentation

## Acceptance Criteria

- **Given** a swipe card is focused
  **When** a screen reader reads the card
  **Then** it announces the candidate's display name, shared interest count, shared interest names, and available actions in a logical order

- **Given** I activate a swipe action via keyboard
  **When** the action completes
  **Then** the screen reader announces the outcome (e.g., "Interest expressed. Moving to next card.")

## Notes
Cards must use ARIA roles: article for the card, group for the action buttons, and live regions for status announcements.
