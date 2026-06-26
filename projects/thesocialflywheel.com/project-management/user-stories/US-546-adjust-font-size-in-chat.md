---
id: US-546
title: "Adjust Font Size in Chat"
slug: adjust-font-size-in-chat
personas: [P-008]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [accessibility, font-size, readability, a11y]
---

# US-546: Adjust Font Size in Chat

## User Story

**As an** Accessibility-First user (P-008)
**I want to** increase or decrease the font size used in chat messages
**So that** I can read comfortably without relying solely on OS-level zoom

## Acceptance Criteria

- **Given** I open Accessibility Settings and locate the Text Size slider
  **When** I drag it to a larger size
  **Then** all message body text, sender names, and timestamps in chat immediately re-render at the new size without requiring a restart

- **Given** I have set a custom app font size
  **When** I update my OS Dynamic Type setting
  **Then** the app font size follows the OS setting unless I have explicitly overridden it in app settings

- **Given** font size is set to the largest option
  **When** I view a long message
  **Then** the message wraps correctly and no text is truncated or overlaps UI chrome

## Notes
Minimum supported size: 12 sp. Maximum: 24 sp. Intermediate step at 16 sp (default). Labels must use relative units (sp / rem) not px.
