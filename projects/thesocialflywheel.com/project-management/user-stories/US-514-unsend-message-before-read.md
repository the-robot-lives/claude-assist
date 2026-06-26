---
id: US-514
title: "Unsend Message Before Read"
slug: unsend-message-before-read
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: medium
tags: [unsend, direct-messages, privacy]
---

# US-514: Unsend Message Before Read

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** retract a message I sent before the recipient has read it
**So that** I can correct regrettable messages without them being seen

## Acceptance Criteria

- **Given** I sent a DM and the recipient has not yet opened the thread
  **When** I choose "Unsend" within 5 minutes of sending
  **Then** the message is deleted server-side before delivery and the recipient never sees it

- **Given** I try to unsend a message that has already been read (read receipt confirmed)
  **When** I choose "Unsend"
  **Then** I am informed the message was already seen and offered "Delete for me only" instead

## Notes
The 5-minute unsend window applies to DMs only. Channel messages use the standard delete flow.
