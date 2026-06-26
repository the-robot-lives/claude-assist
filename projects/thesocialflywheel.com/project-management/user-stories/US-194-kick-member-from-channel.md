---
id: US-194
title: "Kick a Member from Channel"
slug: kick-member-from-channel
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, moderation, kick, safety]
---

# US-194: Kick a Member from Channel

## User Story

**As a** Channel Moderator
**I want to** remove a member from the channel without banning them permanently
**So that** I can enforce community rules while leaving the door open for the member to rejoin after reconsidering their behavior

## Acceptance Criteria

- **Given** I am viewing a member's profile in the channel member directory
  **When** I select "Kick from Channel" from the moderator action menu
  **Then** the member is removed from the channel immediately, their posts remain visible, and they receive a notification that they have been removed

- **Given** a member has been kicked
  **When** they attempt to rejoin the channel
  **Then** they can do so normally (subject to any approval settings), as a kick does not constitute a ban

## Notes
The kick action is logged in the moderation audit trail. Moderators can kick regular members; only the owner can kick moderators. A kicked member is not notified of the reason unless the moderator includes an optional message.
