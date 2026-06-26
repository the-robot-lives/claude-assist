---
id: US-520
title: "Block Effect on Existing Chat Thread"
slug: block-effect-on-existing-chat
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [block, safety, direct-messages]
---

# US-520: Block Effect on Existing Chat Thread

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** block a user and have all messaging between us immediately cease
**So that** I feel safe even if we previously had a DM thread open

## Acceptance Criteria

- **Given** I block a user who I have an existing DM thread with
  **When** the block is applied
  **Then** the thread is archived, neither party can send new messages in it, and the blocked user cannot see my online status

- **Given** a blocked user attempts to message me
  **When** they open what was our DM thread
  **Then** the compose field is disabled and they see a generic message indicating the conversation is unavailable

- **Given** I unblock a user
  **When** the unblock is applied
  **Then** the previous thread history remains accessible to both parties but a new first-message request cycle is required before new messages can be sent

## Notes
Block does not delete historical messages for either party; it only prevents future communication.
