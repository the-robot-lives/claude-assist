---
id: US-159
title: "Set Channel Rules as Moderator"
slug: set-channel-rules
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, rules, moderation, safety]
---

# US-159: Set Channel Rules as Moderator

## User Story

**As a** Channel Moderator
**I want to** write and publish a numbered list of channel rules
**So that** members understand community expectations and I have a reference when taking moderation actions

## Acceptance Criteria

- **Given** I am in the channel's moderation settings
  **When** I add, edit, or remove a rule and tap "Save Rules"
  **Then** the updated rules are immediately visible to all channel members

- **Given** I update existing rules
  **When** the save completes
  **Then** the "last updated" timestamp on the rules page reflects the current date and time

- **Given** I have saved rules
  **When** a member views the channel info page before joining
  **Then** the rules are visible in the pre-join info panel

## Notes
Maximum of 20 rules. Each rule has a title (max 80 chars) and optional description (max 500 chars). Changes are logged in the moderation audit trail.
