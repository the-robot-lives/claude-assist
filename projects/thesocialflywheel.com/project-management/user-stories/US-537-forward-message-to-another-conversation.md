---
id: US-537
title: "Forward Message to Another Conversation"
slug: forward-message-to-another-conversation
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: medium
tags: [forward, sharing, message-management]
---

# US-537: Forward Message to Another Conversation

## User Story

**As a** Bridge-Builder (P-001)
**I want to** forward a message from one conversation to another
**So that** I can share relevant information with a different group without copying and pasting

## Acceptance Criteria

- **Given** I long-press or hover a message and select "Forward"
  **When** the forward sheet opens
  **Then** I see a searchable list of my DM conversations and joined channels and can select one or more destinations (up to 5)

- **Given** I select destinations and tap "Send"
  **When** the message is forwarded
  **Then** each destination receives the original message content with a "Forwarded" label indicating its origin

- **Given** the original message contains a media attachment
  **When** I forward it
  **Then** the attachment is included in the forwarded message without re-uploading (server-side reference copy)

## Notes
Forwarded messages do not reveal the original conversation name or sender to the new destination — only the "Forwarded" label is shown.
