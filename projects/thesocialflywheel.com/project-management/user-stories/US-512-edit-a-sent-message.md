---
id: US-512
title: "Edit a Sent Message"
slug: edit-a-sent-message
personas: [P-009]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [edit, message-management, accuracy]
---

# US-512: Edit a Sent Message

## User Story

**As a** Creator (P-009)
**I want to** edit a message I have already sent to fix typos or clarify content
**So that** my communication remains accurate and professional

## Acceptance Criteria

- **Given** I sent a message less than 24 hours ago
  **When** I long-press it and choose "Edit"
  **Then** the message field is pre-filled with the original text and I can modify and save it

- **Given** I save an edit
  **When** other participants view the message
  **Then** it shows the updated text with an "(edited)" label and a disclosure showing the edit timestamp

- **Given** I attempt to edit a message older than 24 hours
  **When** I try to access the edit option
  **Then** the option is disabled and a tooltip explains the 24-hour edit window

## Notes
Edit history is stored but only visible to the sender and platform moderators.
