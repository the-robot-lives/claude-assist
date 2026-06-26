---
id: US-926
title: "Feed and Message Sync After Reconnect"
slug: sync-after-reconnect
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [sync, reconnect, offline, catchup, websocket]
---

# US-926: Feed and Message Sync After Reconnect

## User Story

**As a** quiet consumer whose connection briefly drops and returns
**I want to** have missed feed posts and chat messages automatically fetched when I reconnect
**So that** I don't have to manually refresh every screen to see what I missed

## Acceptance Criteria

- **Given** my WebSocket connection dropped and I was offline for under 10 minutes
  **When** my connection is restored
  **Then** missed messages and feed posts from the offline period are fetched and inserted in chronological order within 5 seconds

- **Given** I was offline for more than 10 minutes
  **When** I reconnect
  **Then** the app shows a "You were offline — tap to refresh" banner rather than attempting to replay a potentially large backlog

## Notes
Track last-seen message sequence number client-side. On reconnect, request delta since that sequence number. Sequence number must survive app refresh via localStorage.
