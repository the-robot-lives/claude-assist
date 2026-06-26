---
id: US-885
title: "Keyboard Shortcut Panel for Swipe Actions"
slug: swipe-keyboard-shortcuts
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [swipe-alternative, keyboard, shortcuts, accessibility]
---

# US-885: Keyboard Shortcut Panel for Swipe Actions

## User Story

**As a** keyboard-only user in the Swipe-to-Match lane
**I want to** open a discoverable list of keyboard shortcuts
**So that** I can use the most efficient keyboard interactions without guessing what keys are available

## Acceptance Criteria

- **Given** I am in the Swipe-to-Match lane
  **When** I press the ? key
  **Then** a modal opens listing all swipe shortcuts (Right Arrow = Accept, Left Arrow = Skip, Enter = View profile, Escape = Exit deck)

- **Given** the shortcuts modal is open
  **When** I press Escape
  **Then** the modal closes and focus returns to the swipe card I was viewing before opening it

- **Given** I execute a shortcut
  **When** the action succeeds
  **Then** a polite live region announces the action name (e.g., "Card accepted")

## Notes
The shortcut panel should be accessible via both the ? key and a visible "Keyboard shortcuts" button at the bottom of the swipe deck UI. Shortcut definitions must be maintained in a single source shared with the global shortcut reference.
