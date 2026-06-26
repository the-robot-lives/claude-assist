---
id: US-549
title: "Copy Shareable Link to Specific Message"
slug: copy-shareable-link-to-message
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: medium
tags: [deep-link, sharing, message, channel-chat]
---

# US-549: Copy Shareable Link to Specific Message

## User Story

**As a** Bridge-Builder (P-001)
**I want to** copy a direct link to a specific channel message
**So that** I can share it in another context (a DM, an external app) and recipients can jump straight to that message

## Acceptance Criteria

- **Given** I right-click or long-press a channel message and select "Copy link"
  **When** the action completes
  **Then** a deep link URL (e.g., flywheel://channels/[channel-id]/messages/[msg-id]) is copied to my clipboard

- **Given** a recipient opens the copied link
  **When** the app handles the deep link
  **Then** they are taken directly to the channel and the target message is scrolled into view and briefly highlighted

- **Given** a recipient opens the link but does not follow that channel
  **When** the app handles the deep link
  **Then** they see a prompt to join or request access to the channel before the message is revealed

## Notes
Links to messages in private channels should require channel membership to view; public channel messages are accessible to any authenticated user.
