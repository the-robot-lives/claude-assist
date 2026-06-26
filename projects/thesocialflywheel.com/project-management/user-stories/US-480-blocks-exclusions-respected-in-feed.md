---
id: US-480
title: "Ensure blocks and exclusions are respected in the feed"
slug: blocks-exclusions-respected-in-feed
personas: [P-004, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [blocks, exclusions, safety, feed]
---

# US-480: Ensure Blocks and Exclusions Are Respected in the Feed

## User Story

**As a** cautious newcomer (P-004)
**I want to** be certain that users I have blocked never appear in my feed in any lane
**So that** I feel safe and in control of my experience

## Acceptance Criteria

- **Given** I have blocked user @X
  **When** any feed lane loads
  **Then** posts authored by @X are absent from all feed lanes including Discovery and Opposing-Views

- **Given** @X is a mutual of my mutual (2nd degree)
  **When** the feed ranks 2nd-degree posts
  **Then** @X's posts are excluded even if they score highly on interest and recency

- **Given** I mute (not block) a user
  **When** the feed loads
  **Then** their posts are hidden by default but accessible via "Show muted posts" toggle

## Notes
Blocks are bidirectional — if @X blocks me, I also cannot see their posts.
