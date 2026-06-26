---
id: US-229
title: "Swipe to Match Becomes Mutual"
slug: swipe-to-match-becomes-mutual
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [graph, swipe-to-match, requests]
---

# US-229: Swipe to Match Becomes Mutual

## User Story

**As a** Social Connector (P-003)
**I want to** have a Swipe-to-Match interest automatically convert to a full mutual when the other person swipes back
**So that** the transition from one-way interest to reciprocal connection is seamless

## Acceptance Criteria

- **Given** I have swiped right on a user in the Swipe-to-Match lane
  **When** that user subsequently swipes right on me
  **Then** both of us are notified "It's a match! You're now mutuals" and a 1st-degree connection is created instantly

- **Given** a swipe match becomes a mutual
  **When** I view their profile
  **Then** the degree badge shows "1st" and their posts begin appearing in my Mutuals lane on next feed refresh

## Notes
This conversion path bypasses the standard mutual-request flow; no separate "accept" step is needed once reciprocity is established.
