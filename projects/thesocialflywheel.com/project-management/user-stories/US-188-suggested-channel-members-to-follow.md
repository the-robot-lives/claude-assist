---
id: US-188
title: "Suggested Channel Members to Follow"
slug: suggested-channel-members-to-follow
personas: [P-001]
epic: "Interest Channels"
priority: could-have
complexity: medium
tags: [channels, member-directory, suggestions, network, mutuals]
---

# US-188: Suggested Channel Members to Follow

## User Story

**As a** Bridge-Builder
**I want to** see suggestions for channel members I might want to connect with as mutuals
**So that** joining a channel actively helps me grow my trusted network around shared interests

## Acceptance Criteria

- **Given** I have been a channel member for at least 7 days
  **When** I visit the channel's member directory
  **Then** a "People You Might Know" section shows up to 5 non-mutual members ranked by shared channel membership and degree proximity

- **Given** I am shown a suggested member
  **When** I tap "Express Interest"
  **Then** a one-way match interest is sent (feeding the Swipe-to-Match lane) and the suggestion is removed from the list

## Notes
Suggestions should refresh weekly. Members the user has previously dismissed should not reappear for at least 30 days. Suggestions should never surface members the user has blocked.
