---
id: US-163
title: "Engage Swipe-to-Match Lane Within a Channel"
slug: swipe-to-match-lane-in-channel
personas: [P-001]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, lanes, swipe-to-match, discovery, mutuals]
---

# US-163: Engage Swipe-to-Match Lane Within a Channel

## User Story

**As a** Bridge-Builder
**I want to** discover and express interest in non-mutual channel members through the Swipe-to-Match lane
**So that** I can grow my mutual network by connecting with people who share my channel interests

## Acceptance Criteria

- **Given** I am in the Swipe-to-Match lane of a channel
  **When** I swipe right (or tap the match icon) on a post from a non-mutual member
  **Then** a one-way interest is recorded; if they reciprocate, we become mutuals and both receive a notification

- **Given** I am viewing the Swipe-to-Match lane
  **When** I see posts from members I have already expressed interest in (pending reciprocation)
  **Then** those posts are visually marked as "interest sent" to avoid duplicate actions

## Notes
The Swipe-to-Match lane surfaces members within the channel who are within the ≤4th-degree graph or adjacent interest clusters. One-way interests do not grant full interaction access until reciprocated.
