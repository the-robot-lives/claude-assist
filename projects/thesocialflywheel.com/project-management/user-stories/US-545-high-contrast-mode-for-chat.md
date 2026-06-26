---
id: US-545
title: "High-Contrast Mode for Chat"
slug: high-contrast-mode-for-chat
personas: [P-008]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [accessibility, high-contrast, a11y, wcag]
---

# US-545: High-Contrast Mode for Chat

## User Story

**As an** Accessibility-First user (P-008)
**I want to** switch to a high-contrast visual theme in the chat interface
**So that** message text and UI controls are clearly visible against their background

## Acceptance Criteria

- **Given** I enable High Contrast in Accessibility Settings
  **When** the chat view reloads
  **Then** all text meets WCAG AA 4.5:1 contrast ratio against its background and interactive elements (buttons, links) meet 3:1

- **Given** high-contrast mode is active
  **When** I receive a message with a colored reaction bubble
  **Then** the reaction text and border remain legible under the high-contrast palette (no pure-color fills that fail contrast)

- **Given** my device OS is set to "Increase Contrast" (iOS) or "High Contrast Text" (Android)
  **When** I open the app for the first time
  **Then** the app detects the system setting and enables its high-contrast theme automatically

## Notes
High-contrast mode should be tested with both light and dark base themes. Use platform semantic color tokens, not hardcoded hex values.
