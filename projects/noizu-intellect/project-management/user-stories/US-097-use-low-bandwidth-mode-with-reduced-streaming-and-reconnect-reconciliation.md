---
id: US-097
title: "Use low-bandwidth mode with reduced streaming payloads and reconnect reconciliation"
slug: use-low-bandwidth-mode-with-reduced-streaming-and-reconnect-reconciliation
personas: [P-009]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: should-have
complexity: high
tags: [low-bandwidth, streaming, reconnect, pubsub, accessibility]
---

# US-097: Use Low-Bandwidth Mode With Reduced Streaming Payloads and Reconnect Reconciliation

## User Story

**As a** budget hobbyist on an unreliable or metered connection (Rosa Jimenez)
**I want to** switch channels into a low-bandwidth mode that sends coalesced, reduced-frequency updates instead of full token-by-token streaming, and reconcile cleanly after a dropped connection
**So that** I can follow agent activity without burning data or losing my place every time my connection blips

## Acceptance Criteria

- **Given** low-bandwidth mode is enabled for a channel or globally in user settings
  **When** an agent streams a reply
  **Then** the client receives coalesced batched updates (e.g. every N tokens or M milliseconds) instead of per-token PubSub events, with the payload size measurably reduced

- **Given** a client that drops its PubSub/websocket connection mid-stream
  **When** it reconnects
  **Then** it reconciles by fetching the durable inbox delta since its last acknowledged message rather than replaying the full channel history or losing the in-progress message

- **Given** reconnection after a drop that occurred mid-turn
  **When** the client catches up
  **Then** it shows the message as it currently stands (partial-if-still-streaming or complete-if-finished) with no duplicated or out-of-order content

- **Given** low-bandwidth mode is active
  **When** a user views channel activity
  **Then** they can still see accurate live/typing-equivalent status for each agent (e.g. "generating") even though full token streaming is suppressed

## Notes
Distinct from but related to the screen-reader digest mode ([[US-098]]) — both reduce update frequency but for different reasons (bandwidth vs. cognitive/auditory load) and should share the same coalescing infrastructure where feasible. Reconnect reconciliation also benefits general reliability beyond the low-bandwidth persona.
