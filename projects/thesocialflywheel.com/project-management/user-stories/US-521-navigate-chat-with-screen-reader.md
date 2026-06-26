---
id: US-521
title: "Navigate Chat with Screen Reader"
slug: navigate-chat-with-screen-reader
personas: [P-008]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: high
tags: [accessibility, screen-reader, a11y, wcag]
---

# US-521: Navigate Chat with Screen Reader

## User Story

**As an** Accessibility-First user (P-008)
**I want to** navigate DM and channel chat threads using a screen reader (VoiceOver / TalkBack)
**So that** I can read and respond to messages without relying on vision

## Acceptance Criteria

- **Given** I use VoiceOver on iOS or TalkBack on Android with the chat open
  **When** I swipe through the message list
  **Then** each message is announced with sender name, timestamp, message body, and any reaction summary in that order

- **Given** a new message arrives while I am focused in the thread
  **When** the message is rendered
  **Then** the screen reader announces "New message from [Name]" without losing my current focus position

- **Given** I focus the compose field
  **When** I double-tap to activate
  **Then** the keyboard opens, my cursor is in the text field, and send button is reachable in one swipe right

## Notes
All interactive elements (reactions, thread buttons, attachment button) must have descriptive accessibility labels. WCAG 2.1 AA required.
