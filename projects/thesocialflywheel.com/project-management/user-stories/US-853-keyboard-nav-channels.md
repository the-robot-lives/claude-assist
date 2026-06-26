---
id: US-853
title: "Keyboard Navigation in Channel Sidebar"
slug: keyboard-nav-channels
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [keyboard-navigation, channels, wcag-2.2]
---

# US-853: Keyboard Navigation in Channel Sidebar

## User Story

**As a** keyboard-only user
**I want to** navigate the channel list with Up/Down arrow keys and expand/collapse groups with Enter
**So that** I can switch channels efficiently

## Acceptance Criteria

- **Given** the channel sidebar is focused
  **When** I press Down Arrow
  **Then** focus moves to the next channel in the list

- **Given** a channel group is focused
  **When** I press Enter
  **Then** the group expands or collapses

- **Given** a channel is focused
  **When** I press Enter
  **Then** that channel opens and focus moves to the message input

## Notes

Implement the sidebar using role="tree" / role="treeitem" with aria-expanded on group nodes. Include aria-level to convey nesting depth to screen readers.
