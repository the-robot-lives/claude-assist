---
id: US-522
title: "Navigate Chat with Keyboard Only"
slug: navigate-chat-with-keyboard
personas: [P-008]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [accessibility, keyboard-navigation, a11y, wcag]
---

# US-522: Navigate Chat with Keyboard Only

## User Story

**As an** Accessibility-First user (P-008)
**I want to** use the chat interface entirely via keyboard (Tab, Arrow keys, Enter, Escape)
**So that** I can participate without a mouse or touch screen

## Acceptance Criteria

- **Given** I am on the chat view using a desktop or connected keyboard
  **When** I press Tab
  **Then** focus moves in logical document order through the conversation list, message thread, compose area, and action buttons without any dead ends or focus traps (except modals)

- **Given** a message in the thread has keyboard focus
  **When** I press the context menu key or Shift+F10
  **Then** the message action menu (React, Reply, Edit, Delete) opens and is navigable with arrow keys

- **Given** I am composing a message
  **When** I press Enter
  **Then** the message is sent; Shift+Enter inserts a line break

## Notes
All keyboard shortcuts must be documented in a discoverable help overlay (? key).
