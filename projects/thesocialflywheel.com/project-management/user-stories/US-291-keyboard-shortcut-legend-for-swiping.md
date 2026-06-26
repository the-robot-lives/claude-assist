---
id: US-291
title: "Keyboard Shortcut Legend for Swiping"
slug: keyboard-shortcut-legend-for-swiping
personas: [P-008]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [accessibility, keyboard, a11y, documentation]
---

# US-291: Keyboard Shortcut Legend for Swiping

## User Story

**As an** Accessibility-First user (P-008)
**I want to** see a persistently accessible keyboard shortcut reference in the swipe lane
**So that** I do not have to memorize bindings or leave the flow to find them

## Acceptance Criteria

- **Given** I am in the swipe lane
  **When** I press ? or activate the "Keyboard shortcuts" link
  **Then** a modal or side-drawer lists all swipe-lane keyboard shortcuts with their actions

- **Given** the shortcut legend is open
  **When** I press Escape or activate the close button
  **Then** focus returns to the swipe card I was viewing and the legend closes
