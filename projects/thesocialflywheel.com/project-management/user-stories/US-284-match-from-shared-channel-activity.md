---
id: US-284
title: "Match From Shared Channel Activity"
slug: match-from-shared-channel-activity
personas: [P-002]
epic: "Swipe-to-Match"
priority: should-have
complexity: high
tags: [interest-matching, channel, activity-signal]
---

# US-284: Match From Shared Channel Activity

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** have the matching algorithm weight channel activity (posts, reactions, comments) not just channel membership
**So that** candidates surfaced to me are people who are genuinely active in our shared topic, not just subscribed

## Acceptance Criteria

- **Given** a candidate follows a channel I follow but has not posted in 90 days
  **When** the matching algorithm ranks candidates
  **Then** this candidate scores lower than one who posted in the last 7 days

- **Given** a candidate and I have both reacted to posts in the same thread
  **When** that channel is a shared interest
  **Then** the co-engagement is used as a positive signal to boost their rank in my queue
