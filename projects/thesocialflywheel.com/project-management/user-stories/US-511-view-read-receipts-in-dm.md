---
id: US-511
title: "View Read Receipts in DM"
slug: view-read-receipts-in-dm
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [direct-messages, read-receipts, feedback]
---

# US-511: View Read Receipts in DM

## User Story

**As a** Social Connector (P-003)
**I want to** see whether my DM has been read by the recipient
**So that** I know whether to follow up or wait

## Acceptance Criteria

- **Given** I have sent a DM to a mutual
  **When** the recipient opens the thread and their screen scrolls past my message
  **Then** a "Seen" label or the recipient's avatar appears beneath my last read message

- **Given** the recipient has disabled read receipts in their privacy settings
  **When** they read my message
  **Then** no read receipt is shown to me, and I also do not send read receipts to them (reciprocal opt-out)

## Notes
Read receipts are only available in 1-on-1 DMs, not in group chats, to avoid social pressure at scale.
