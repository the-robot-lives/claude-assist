---
id: US-501
title: "Send DM to Mutual"
slug: send-dm-to-mutual
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [direct-messages, mutuals, messaging]
---

# US-501: Send DM to Mutual

## User Story

**As a** Social Connector (P-003)
**I want to** open a direct message thread with any of my mutuals
**So that** I can have private one-on-one conversations outside of public channels

## Acceptance Criteria

- **Given** I am viewing a mutual's profile
  **When** I tap "Message"
  **Then** a DM thread opens (or is created if first contact) and I can type and send a message

- **Given** I have an existing DM thread with a mutual
  **When** I navigate to the Messages tab
  **Then** the thread appears in my conversation list and I can resume the conversation

## Notes
DM threads persist even if the mutual relationship later changes, but new messages are blocked if they are no longer mutuals.
