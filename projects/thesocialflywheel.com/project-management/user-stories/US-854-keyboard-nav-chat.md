---
id: US-854
title: "Keyboard Navigation in Chat Thread"
slug: keyboard-nav-chat
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [keyboard-navigation, chat, wcag-2.2]
---

# US-854: Keyboard Navigation in Chat Thread

## User Story

**As a** keyboard-only user
**I want to** have full keyboard access to the chat thread—scrolling, replying, reacting
**So that** I can participate in conversations without a mouse

## Acceptance Criteria

- **Given** the chat thread is focused
  **When** I press Up/Down Arrow
  **Then** I scroll through messages one at a time with each focused message announced

- **Given** a message is focused
  **When** I press R
  **Then** the reply composer opens with focus placed in the input field

- **Given** a message is focused
  **When** I press E
  **Then** the emoji reaction picker opens and is fully keyboard-navigable

## Notes

Keyboard shortcuts (R, E) should only fire when focus is on a message element to avoid conflicts with the composer. Document shortcuts in an accessible help overlay reachable via a keyboard shortcut (e.g. Shift+?).
