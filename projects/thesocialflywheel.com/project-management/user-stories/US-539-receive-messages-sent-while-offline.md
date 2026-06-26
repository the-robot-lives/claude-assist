---
id: US-539
title: "Receive Messages Sent While Offline"
slug: receive-messages-sent-while-offline
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [offline, delivery, reliability]
---

# US-539: Receive Messages Sent While Offline

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** receive all messages that were sent to me while I had no internet connection
**So that** I never miss a conversation even if my connectivity is unreliable

## Acceptance Criteria

- **Given** I was offline for up to 30 days and receive new messages during that time
  **When** I reconnect and open the app
  **Then** all queued messages are delivered in chronological order and conversation lists update to reflect unread counts

- **Given** I reconnect after being offline
  **When** the sync completes
  **Then** I see a subtle "Synced" indicator and any conversations with new messages are surfaced at the top of my list

- **Given** a mutual sent me multiple messages in a burst while I was offline
  **When** I receive them
  **Then** they appear as individual messages with their original timestamps, not batched

## Notes
Messages older than 30 days that were not delivered are discarded with a server-side expiry notice.
