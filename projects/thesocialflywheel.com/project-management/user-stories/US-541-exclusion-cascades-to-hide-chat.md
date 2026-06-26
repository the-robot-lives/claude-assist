---
id: US-541
title: "Exclusion Cascades to Hide Chat"
slug: exclusion-cascades-to-hide-chat
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: high
tags: [exclusion, block, cascade, safety]
---

# US-541: Exclusion Cascades to Hide Chat

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** apply a cascade exclusion so that any shared group chats with the excluded user are also hidden from me
**So that** I can fully remove an unwanted presence from my messaging experience

## Acceptance Criteria

- **Given** I exclude a user with the "cascade" option enabled
  **When** the exclusion is applied
  **Then** all group chats that include both me and the excluded user are hidden from my conversation list

- **Given** a group chat is hidden by cascade exclusion
  **When** the excluded user leaves that group
  **Then** the group chat is automatically restored to my conversation list

- **Given** I apply exclusion without cascade
  **When** the exclusion is applied
  **Then** only direct contact with the excluded user is blocked; shared group chats remain visible but the excluded user's messages in them appear collapsed/hidden

## Notes
Cascade exclusion is a one-way action; the excluded user is not aware of the cascade. Group membership is not changed — only visibility.
