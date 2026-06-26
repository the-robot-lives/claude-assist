---
id: US-900
title: "Accessible Swipe History Review"
slug: swipe-history-review
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: could-have
complexity: medium
tags: [swipe-alternative, accessibility, history, keyboard]
---

# US-900: Accessible Swipe History Review

## User Story

**As a** screen-reader or keyboard-only user
**I want to** review and undo recent swipe decisions from an accessible list view
**So that** I can correct mistakes made while navigating the swipe deck without visual confirmation

## Acceptance Criteria

- **Given** I have swiped on at least one card
  **When** I open "Swipe History"
  **Then** a keyboard-navigable table lists recently swiped profiles with columns for name, decision (Accepted/Skipped), and timestamp — all announced by the screen reader

- **Given** I locate a decision I want to reverse in the history table
  **When** I activate the "Undo" button in that row
  **Then** the decision is reversed and a polite live region confirms "[Name]: decision reversed"

- **Given** the swipe history list has more entries than fit on one page
  **When** I tab to the pagination controls
  **Then** "Previous page" and "Next page" buttons are clearly labelled, keyboard accessible, and announce the current page number after navigation

## Notes
The undo action should be available only within a defined time window (e.g., 24 hours) after the swipe decision. Expired undo options should show "Undo unavailable" with an explanatory tooltip accessible via keyboard.
