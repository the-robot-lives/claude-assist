---
id: US-181
title: "Edit Channel Description"
slug: edit-channel-description
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, description, moderation, settings]
---

# US-181: Edit Channel Description

## User Story

**As a** Channel Moderator
**I want to** update the channel's name and description at any time
**So that** the channel accurately represents the community as it evolves

## Acceptance Criteria

- **Given** I am in channel settings with owner or moderator permissions
  **When** I edit the description and save
  **Then** the updated description is immediately reflected on the channel info page and in the directory listing

- **Given** I attempt to save a description that exceeds the character limit
  **When** I tap Save
  **Then** a character count indicator shows the overage and the save is blocked until I trim the text

## Notes
Description max: 280 chars. Name max: 64 chars. Only the owner can change the channel name; moderators can edit the description but not the name. Name changes are logged in the audit trail.
