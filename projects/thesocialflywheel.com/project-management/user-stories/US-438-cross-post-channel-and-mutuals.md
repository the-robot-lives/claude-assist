---
id: US-438
title: "Cross-post to a channel and mutuals feed simultaneously"
slug: cross-post-channel-and-mutuals
personas: [P-001]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [cross-post, channels, mutuals, reach]
---

# US-438: Cross-Post to a Channel and Mutuals Feed Simultaneously

## User Story

**As a** Bridge-Builder
**I want to** publish a post that appears in both a channel feed and my mutuals' home feed at the same time
**So that** I reach both my personal network and the broader channel community with a single action

## Acceptance Criteria

- **Given** I am composing a post
  **When** I select a channel destination AND leave the audience setting at "mutuals"
  **Then** the post is published to both destinations

- **Given** the post appears in both the channel and mutuals feed
  **When** a recipient views it in either context
  **Then** it is the same post object (same reactions, same replies)

## Notes
Engagement (likes, replies) is unified across both appearances of the post.
