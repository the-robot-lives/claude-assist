---
id: US-530
title: "View Message Timestamps"
slug: view-message-timestamps
personas: [P-010]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [timestamps, readability, context]
---

# US-530: View Message Timestamps

## User Story

**As a** Skeptical Switcher (P-010)
**I want to** see when each message was sent without the interface feeling cluttered
**So that** I can understand conversation context and gauge response times

## Acceptance Criteria

- **Given** I am viewing a chat thread
  **When** messages are from the same day
  **Then** a date divider ("Today," "Yesterday," or "Mon Jun 23") appears at day boundaries and only the time (e.g., 3:42 PM) is shown per message on hover or tap

- **Given** I tap or hover a specific message
  **When** the timestamp appears
  **Then** it shows the full date and time in my local timezone (e.g., "Mon Jun 23, 2026 at 3:42 PM EDT")

- **Given** I use a 24-hour time preference
  **When** any timestamp is rendered
  **Then** it respects my system or app locale and shows 24-hour format

## Notes
Timestamps should not be shown inline for every message to preserve readability; reveal on interaction.
