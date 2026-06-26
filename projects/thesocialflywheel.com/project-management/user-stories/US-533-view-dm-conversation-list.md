---
id: US-533
title: "View DM Conversation List"
slug: view-dm-conversation-list
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [direct-messages, inbox, navigation]
---

# US-533: View DM Conversation List

## User Story

**As a** Social Connector (P-003)
**I want to** see an organized list of all my direct message conversations
**So that** I can quickly find and navigate to any active thread

## Acceptance Criteria

- **Given** I tap the Messages tab
  **When** the view loads
  **Then** conversations are listed in reverse chronological order by latest message, each showing: avatar, name, message preview (first 60 chars), and elapsed time

- **Given** one or more conversations have unread messages
  **When** I view the list
  **Then** unread threads are visually distinguished (bold name, unread badge count) and sorted above read threads

- **Given** I have more than 50 conversations
  **When** I scroll to the bottom of the list
  **Then** older conversations load lazily so initial render stays under 1 second

## Notes
Pinned conversations should appear in a separate sticky section at the very top, regardless of recency.
