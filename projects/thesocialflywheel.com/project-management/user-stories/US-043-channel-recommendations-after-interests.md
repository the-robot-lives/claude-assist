---
id: US-043
title: "Channel Recommendations After Interest Selection"
slug: channel-recommendations-after-interests
personas: [P-002, P-004, P-001]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [channels, recommendations, interests, onboarding]
---

# US-043: Channel Recommendations After Interest Selection

## User Story

**As a** niche enthusiast
**I want to** see recommended channels based on my selected interests immediately after choosing them
**So that** I can join communities before I have any mutuals

## Acceptance Criteria

- **Given** I have selected 3+ interests
  **When** I proceed past the interest selection screen
  **Then** I see a "Channels for you" screen listing at least 5 channels matching my interests with member counts and sample posts.

- **Given** I tap "Join" on a channel
  **When** confirmed
  **Then** I am subscribed and the channel appears in my sidebar; the Mutuals lane shows the empty state and Opposing Views begins populating.

## Notes
Show a "preview" sample post per channel before joining (no posting access until joined). Limit to 10 recommendations in onboarding to avoid overwhelm.
