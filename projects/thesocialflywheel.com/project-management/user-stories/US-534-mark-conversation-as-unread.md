---
id: US-534
title: "Mark Conversation as Unread"
slug: mark-conversation-as-unread
personas: [P-006]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: low
tags: [direct-messages, unread, organization]
---

# US-534: Mark Conversation as Unread

## User Story

**As a** Quiet Consumer (P-006)
**I want to** mark a conversation as unread after I have read it
**So that** I can flag it as something to return to without any other reminder tool

## Acceptance Criteria

- **Given** I long-press a conversation in the Messages list
  **When** I select "Mark as unread"
  **Then** the thread immediately displays the unread styling (bold name, badge) in my list without any actual message being marked unread for the other party

- **Given** I open a conversation I marked as unread
  **When** I read the latest message
  **Then** the unread styling is cleared and the conversation returns to its normal read state

## Notes
"Mark as unread" is a client-side flag; it does not affect the other party's read-receipt state.
