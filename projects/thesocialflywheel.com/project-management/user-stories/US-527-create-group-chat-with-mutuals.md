---
id: US-527
title: "Create Group Chat with Mutuals"
slug: create-group-chat-with-mutuals
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [group-chat, mutuals, creation]
---

# US-527: Create Group Chat with Mutuals

## User Story

**As a** Social Connector (P-003)
**I want to** create a group chat and invite multiple mutuals to it
**So that** I can coordinate with several friends in one shared thread

## Acceptance Criteria

- **Given** I tap "New group chat" in the Messages tab
  **When** the creation flow opens
  **Then** I can search my mutuals list, select up to 49 participants, set a group name and optional avatar, and confirm creation

- **Given** I confirm the group
  **When** the chat is created
  **Then** all invited members receive a notification and the thread appears in their conversation lists; I am set as admin

- **Given** I invite a mutual to a group
  **When** that mutual views the invitation
  **Then** they can accept or decline before any messages they send appear to others

## Notes
Only mutuals can be added to a group. The group name is required; max 100 characters.
