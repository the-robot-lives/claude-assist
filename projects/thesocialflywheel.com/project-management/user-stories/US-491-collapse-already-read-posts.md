---
id: US-491
title: "Collapse already-read posts in feed"
slug: collapse-already-read-posts
personas: [P-006]
epic: "Feed & Ranking"
priority: could-have
complexity: medium
tags: [read-state, collapse, feed-control, ux]
---

# US-491: Collapse Already-Read Posts in Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** have already-read posts automatically collapsed to a single line
**So that** I can skim through the feed faster during return visits without re-reading content

## Acceptance Criteria

- **Given** I enable "Collapse read posts" in Feed Preferences
  **When** I scroll through the feed
  **Then** posts I previously read display as a single collapsed row showing only author and timestamp

- **Given** a read post is collapsed
  **When** I tap it
  **Then** it expands to full preview in place

- **Given** "Collapse read posts" is off (default)
  **When** I view the feed
  **Then** all posts render at full preview size regardless of read state

## Notes
Read state used here is the same auto-read signal from US-468 (viewport dwell ≥2 seconds).
