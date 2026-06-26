---
id: US-476
title: "Discover new content via the Discovery lane"
slug: discovery-lane
personas: [P-004, P-003]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [discovery, lane, new-connections, channels]
---

# US-476: Discover New Content via the Discovery Lane

## User Story

**As a** cautious newcomer (P-004)
**I want to** see a rotating selection of Discovery posts from popular channels
**So that** I can find new interests and potential connections without feeling overwhelmed

## Acceptance Criteria

- **Given** the home feed loads
  **When** Discovery posts appear
  **Then** they are labelled "Discovery" and show the post's source channel and the posting user's public profile teaser

- **Given** I tap "Follow this channel" on a Discovery post
  **When** the action completes
  **Then** the channel is added to my subscriptions and the Discovery post converts to a standard feed post

- **Given** I dismiss multiple Discovery posts from the same channel
  **When** the feed refreshes
  **Then** that channel's Discovery posts are suppressed for 7 days

## Notes
Discovery rotation refreshes every 6 hours to surface fresh channels.
