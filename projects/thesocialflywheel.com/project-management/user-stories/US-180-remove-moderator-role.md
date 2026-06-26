---
id: US-180
title: "Remove Moderator Role in Channel"
slug: remove-moderator-role
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, moderation, roles, ownership]
---

# US-180: Remove Moderator Role in Channel

## User Story

**As a** Channel Moderator (owner)
**I want to** revoke a moderator's elevated role
**So that** I can manage the mod team as the community evolves and address cases of moderator misuse

## Acceptance Criteria

- **Given** I am the channel owner in channel settings
  **When** I select a moderator and tap "Remove Moderator"
  **Then** the member's role is downgraded to regular member, they lose moderation permissions immediately, and receive a notification

- **Given** a moderator's role has been removed
  **When** I view the moderation audit trail
  **Then** the demotion event is recorded with a timestamp and the acting owner's identity

## Notes
Only the channel owner can remove moderators. A moderator cannot remove another moderator. The action is immediate with no cooldown period.
