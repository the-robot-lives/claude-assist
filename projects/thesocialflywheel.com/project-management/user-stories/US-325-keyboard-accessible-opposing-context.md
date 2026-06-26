---
id: US-325
title: "Keyboard-Accessible Opposing Post Context"
slug: keyboard-accessible-opposing-context
personas: [P-008]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, accessibility, keyboard, a11y]
---

# US-325: Keyboard-Accessible Opposing Post Context

## User Story

**As an** accessibility-first user
**I want to** access the "why you're seeing this" context popover for an opposing-view post using only my keyboard
**So that** I have the same transparency as pointer-device users without needing a mouse

## Acceptance Criteria

- **Given** I am navigating with a keyboard
  **When** focus is on the "Opposing view on [Interest]" label
  **Then** pressing Enter or Space opens the context popover

- **Given** the context popover is open
  **When** I press Escape
  **Then** the popover closes and focus returns to the label

## Notes
Popover must trap focus while open. All interactive elements within the popover must be reachable by Tab.
