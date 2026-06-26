---
id: US-470
title: "Access a ranking transparency explanation"
slug: ranking-transparency-explanation
personas: [P-001, P-010]
epic: "Feed & Ranking"
priority: must-have
complexity: low
tags: [transparency, ranking, trust, no-virality]
---

# US-470: Access a Ranking Transparency Explanation

## User Story

**As a** skeptical switcher (P-010)
**I want to** read a plain-language explanation of how the feed is ranked
**So that** I can verify there is no hidden virality, engagement-bait boosting, or ad-driven ranking

## Acceptance Criteria

- **Given** I am on the home feed
  **When** I tap "How is my feed ranked?" in the feed header menu
  **Then** a modal opens explaining the three signals: connection degree, channel interest match, and post recency — with no mention of likes, shares, or engagement metrics

- **Given** I am reading the transparency modal
  **When** I look for any mention of advertising or promoted content
  **Then** none exists (the platform explicitly states "No ads, no promoted posts, no engagement-based ranking")

## Notes
This page should be linkable from onboarding and account settings, not just the feed.
