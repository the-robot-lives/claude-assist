---
id: US-934
title: "Automatic WebSocket Reconnection With Backoff"
slug: websocket-reconnection
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [websocket, reconnection, backoff, real-time, resilience]
---

# US-934: Automatic WebSocket Reconnection With Backoff

## User Story

**As a** quiet consumer keeping the app open in a browser tab for hours
**I want to** have the WebSocket connection automatically re-established after a drop
**So that** I don't miss real-time updates or have to reload the page

## Acceptance Criteria

- **Given** my WebSocket connection drops unexpectedly
  **When** the disconnection is detected
  **Then** the client attempts to reconnect with exponential backoff (1 s, 2 s, 4 s, max 30 s)

- **Given** reconnection succeeds
  **When** the connection is established
  **Then** any missed messages are fetched via catch-up API and a "Reconnected" status indicator briefly appears

## Notes
Cap total reconnect attempts to 10 before surfacing a manual "Reconnect" button. Track connection state visibly (dot indicator) in the UI header. Jitter backoff to prevent thundering herd on server restarts.
