---
id: US-851
title: "Keyboard Navigation in Feed"
slug: keyboard-nav-feed
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [keyboard-navigation, feed, wcag-2.2]
---

# US-851: Keyboard Navigation in Feed

## User Story

**As a** keyboard-only user
**I want to** move through the feed using Tab/Arrow keys
**So that** I can browse posts without a mouse

## Acceptance Criteria

- **Given** the feed is open
  **When** I press Tab
  **Then** focus moves to the next post card with a visible focus ring

- **Given** I am on a post card
  **When** I press Enter
  **Then** the post expands

- **Given** I am at the bottom of loaded posts
  **When** I press Tab past the last card
  **Then** focus moves to the "Load more" button

## Notes

Ensure focus ring meets WCAG 2.2 Focus Appearance (3:1 contrast, minimum area). Post cards should use a single focusable container with internal tab stops only when expanded.
