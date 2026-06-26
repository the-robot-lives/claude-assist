---
id: US-943
title: "Batched Read Receipt Transmission"
slug: read-receipt-batching
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: could-have
complexity: low
tags: [read-receipts, batching, api-efficiency, chat]
---

# US-943: Batched Read Receipt Transmission

## User Story

**As a** quiet consumer reading through a busy channel
**I want to** have read receipts sent in batches rather than per-message
**So that** the app doesn't flood the server with individual read events as I scroll through hundreds of messages

## Acceptance Criteria

- **Given** I am scrolling through channel messages
  **When** messages enter and leave the viewport
  **Then** read events are buffered client-side and flushed to the server in a single batch every 5 seconds

- **Given** I close the channel view
  **When** there are unflushed read receipts in the buffer
  **Then** the buffer is flushed immediately before navigation completes

## Notes
Use `visibilitychange` event and `pagehide` to trigger early flush. Batch endpoint accepts array of `{ messageId, readAt }`. Do not send receipt for messages already marked read in a previous session.
