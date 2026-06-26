---
id: US-518
title: "Leave a Group Chat"
slug: leave-a-group-chat
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [group-chat, leave, control]
---

# US-518: Leave a Group Chat

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** leave a group chat I no longer want to participate in
**So that** I stop receiving messages and can reclaim my attention

## Acceptance Criteria

- **Given** I am a member of a group chat
  **When** I open group settings and tap "Leave group"
  **Then** I am immediately removed from the member list and stop receiving future messages

- **Given** I leave a group chat
  **When** remaining members view the thread
  **Then** a system message reads "[Username] left the group" at the point of departure

- **Given** I am the only admin and try to leave
  **When** I tap "Leave group"
  **Then** I am prompted to assign a new admin before I can leave, or to disband the group entirely

## Notes
Left group chats are archived in the user's chat history but marked as inactive. They cannot be rejoined without a new invitation.
