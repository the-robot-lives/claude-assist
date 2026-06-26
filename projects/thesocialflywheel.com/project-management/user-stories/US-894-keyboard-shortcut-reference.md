---
id: US-894
title: "Global Keyboard Shortcut Reference Overlay"
slug: keyboard-shortcut-reference
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [keyboard, shortcuts, accessibility]
---

# US-894: Global Keyboard Shortcut Reference Overlay

## User Story

**As a** keyboard-only user
**I want to** open a comprehensive shortcut reference overlay from anywhere in the app
**So that** I can discover and recall available keyboard commands without leaving the product

## Acceptance Criteria

- **Given** any page is active
  **When** I press Shift+?
  **Then** a modal overlay opens listing all keyboard shortcuts grouped by context (Feed, Chat, Swipe, Global)

- **Given** the shortcut modal is open
  **When** I type in the search field
  **Then** shortcut entries filter in real time matching the keyword, with results announced via a polite live region

- **Given** the modal is open
  **When** I press Escape
  **Then** the modal closes and focus returns exactly to the element that had focus before I opened it

## Notes
The shortcut catalog must be a single source of truth shared between this overlay and the context-specific shortcut panels (e.g., the Swipe shortcut panel in US-885). Shortcut key names must use the user's OS convention (Cmd on macOS, Ctrl on Windows/Linux).
