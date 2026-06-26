---
id: US-528
title: "Add or Remove Group Chat Members"
slug: add-or-remove-group-chat-members
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: medium
tags: [group-chat, member-management, admin]
---

# US-528: Add or Remove Group Chat Members

## User Story

**As a** Channel Moderator (P-007)
**I want to** add new members to or remove existing members from a group chat I administer
**So that** I can keep the conversation relevant as the social circle evolves

## Acceptance Criteria

- **Given** I am the group admin and tap "Manage members"
  **When** I choose "Add members"
  **Then** I see a list of my mutuals who are not yet in the group and can select and invite them

- **Given** I tap "Remove" next to a member
  **When** I confirm the removal
  **Then** that member is immediately removed, sees a "You were removed from [Group Name]" notice, and a system message appears in the thread

- **Given** a non-admin member tries to add or remove participants
  **When** they view the group settings
  **Then** add/remove controls are hidden and only their own "Leave group" option is available

## Notes
New members can only read messages sent after they joined; prior history is hidden.
