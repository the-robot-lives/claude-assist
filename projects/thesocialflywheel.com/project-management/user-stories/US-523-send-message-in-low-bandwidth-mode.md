---
id: US-523
title: "Send Message in Low-Bandwidth Mode"
slug: send-message-in-low-bandwidth-mode
personas: [P-010]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: high
tags: [low-bandwidth, performance, offline, resilience]
---

# US-523: Send Message in Low-Bandwidth Mode

## User Story

**As a** Skeptical Switcher (P-010)
**I want to** send and receive text messages even on a slow or intermittent connection
**So that** the chat remains usable when I am on mobile data or a poor Wi-Fi signal

## Acceptance Criteria

- **Given** my network connection is detected as below 200 kbps
  **When** low-bandwidth mode activates automatically
  **Then** inline images and video previews are replaced with placeholder cards, reducing data usage by at least 80%

- **Given** I send a message while temporarily offline
  **When** connectivity returns within 60 seconds
  **Then** the message is delivered automatically with no user action and the "Sending…" indicator resolves to a sent checkmark

- **Given** I have been offline for more than 60 seconds with a queued message
  **When** I regain connectivity
  **Then** I am notified that a queued message is pending and given the option to send or discard it

## Notes
Low-bandwidth mode can also be toggled manually in Settings > Data Usage.
