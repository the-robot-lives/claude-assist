---
id: US-167
title: "Pin a Post in Channel"
slug: pin-post-in-channel
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, pinned-posts, moderation]
---

# US-167: Pin a Post in Channel

## User Story

**As a** Channel Moderator
**I want to** pin important posts to the top of the channel feed
**So that** all members immediately see critical announcements, introductions, or reference content

## Acceptance Criteria

- **Given** I am a moderator viewing a post in the channel feed
  **When** I open the post's action menu and select "Pin Post"
  **Then** the post moves to a pinned section at the top of the channel feed and is visually distinguished with a pin icon

- **Given** I attempt to pin a post when 5 posts are already pinned
  **When** I select "Pin Post"
  **Then** I am told the maximum pin limit has been reached and must unpin another post first

## Notes
Maximum of 5 pinned posts per channel. Pinned posts remain until explicitly unpinned; they do not expire. Both the channel owner and any assigned moderator can pin/unpin.
