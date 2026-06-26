---
id: US-907
title: "Queued Action Retry on Reconnect"
slug: queued-action-retry
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [offline, retry, background-sync, queue]
---

# US-907: Queued Action Retry on Reconnect

## User Story

**As a** skeptical switcher whose connection drops mid-session
**I want to** have my likes, follows, and posts automatically retried when my connection returns
**So that** I don't lose actions I already performed and don't have to redo them manually

## Acceptance Criteria

- **Given** I submitted a post while offline (queued)
  **When** my device reconnects to the internet
  **Then** the queued post is sent within 30 seconds without any manual intervention

- **Given** multiple queued actions exist on reconnect
  **When** they are processed
  **Then** they are replayed in chronological order and I receive a single summary notification of what was sent

## Notes
Implement via Background Sync API where available; fall back to in-memory retry on foreground reconnect event. Max retry window: 24 hours, after which the user is notified of expiry.
