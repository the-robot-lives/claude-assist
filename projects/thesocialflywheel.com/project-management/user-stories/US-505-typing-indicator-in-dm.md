---
id: US-505
title: "Typing Indicator in DM"
slug: typing-indicator-in-dm
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [direct-messages, typing-indicator, presence]
---

# US-505: Typing Indicator in DM

## User Story

**As a** Social Connector (P-003)
**I want to** see a typing indicator when the other person is composing a reply in a DM thread
**So that** I know they are actively engaged and can wait for their response

## Acceptance Criteria

- **Given** both parties are in an active DM thread
  **When** the other person starts typing
  **Then** a "… is typing" indicator appears at the bottom of the thread within 1 second

- **Given** the other person stops typing without sending
  **When** 5 seconds pass with no keystrokes
  **Then** the typing indicator disappears automatically

## Notes
The typing signal should not be sent if the user has enabled "hide typing status" in privacy settings.
