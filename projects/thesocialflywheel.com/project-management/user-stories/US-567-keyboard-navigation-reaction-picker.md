---
id: US-567
title: "Navigate the Reaction Picker with a Keyboard"
slug: keyboard-navigation-reaction-picker
personas: [P-008]
epic: "Reactions & Engagement"
priority: must-have
complexity: medium
tags: [accessibility, keyboard, reactions]
---

# US-567: Navigate the Reaction Picker with a Keyboard

## User Story

**As an** Accessibility-First user
**I want to** open and navigate the reaction picker using only my keyboard
**So that** I can engage without a mouse or touch screen

## Acceptance Criteria

- **Given** focus is on a post
  **When** I press Enter on the reaction button
  **Then** the picker opens and focus moves to the first emoji automatically

- **Given** the picker is open
  **When** I use arrow keys
  **Then** focus moves between emojis in reading order; pressing Enter selects the focused emoji

- **Given** the picker is open
  **When** I press Escape
  **Then** the picker closes and focus returns to the reaction button

## Notes
All interactive elements must have visible focus indicators meeting WCAG 2.1 AA. Tab order must be logical.
