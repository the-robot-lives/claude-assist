---
id: US-179
title: "Assign Moderator Role in Channel"
slug: assign-moderator-role
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, moderation, roles, ownership]
---

# US-179: Assign Moderator Role in Channel

## User Story

**As a** Channel Moderator (owner)
**I want to** promote a channel member to moderator
**So that** I can distribute community management responsibilities across trusted members

## Acceptance Criteria

- **Given** I am the channel owner and I open the member directory in channel settings
  **When** I tap a member and select "Make Moderator"
  **Then** the member is immediately granted moderator permissions and receives a notification of their new role

- **Given** a member has been made a moderator
  **When** other members view the channel's member directory
  **Then** that member's entry displays a moderator badge

## Notes
Maximum of 10 moderators per channel (excluding owner). Moderators can pin posts, edit rules, kick members, and archive subtopics but cannot transfer ownership or remove other moderators.
