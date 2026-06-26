---
id: US-555
title: "Understand Discovery Lane Engagement Limits"
slug: discovery-lane-engagement-limits
personas: [P-004]
epic: "Reactions & Engagement"
priority: should-have
complexity: low
tags: [discovery, read-only, onboarding]
---

# US-555: Understand Discovery Lane Engagement Limits

## User Story

**As a** Cautious Newcomer
**I want to** understand which engagement actions are available in the Discovery lane
**So that** I don't accidentally violate platform rules when browsing new content

## Acceptance Criteria

- **Given** I am browsing the Discovery lane
  **When** I view a post from someone outside my web
  **Then** only a "Save" action is available; reactions and replies are hidden

- **Given** I tap "Save" on a Discovery post
  **Then** the post is bookmarked and I may optionally initiate a Swipe-to-Match flow with the author

## Notes
Discovery lane engagement rules may relax as the user's web grows; surface this contextually via a nudge.
