---
id: US-165
title: "Add Interest Tags to Channel"
slug: add-interest-tags-to-channel
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, interest-tags, moderation, discovery]
---

# US-165: Add Interest Tags to Channel

## User Story

**As a** Channel Moderator
**I want to** add or update interest tags on my channel
**So that** the channel appears in the right tag-filtered searches and is surfaced to users with matching interest profiles

## Acceptance Criteria

- **Given** I am in the channel settings
  **When** I add a new interest tag from the platform tag list and save
  **Then** the tag appears on the channel's info page and is immediately indexed for discovery

- **Given** I attempt to add more than the maximum allowed tags
  **When** I try to save
  **Then** I receive a validation error specifying the tag limit and am asked to remove one before saving

## Notes
Maximum of 10 interest tags per channel. Tags must be selected from a curated platform-wide list; free-text custom tags are not permitted. At least 1 tag is required at channel creation.
