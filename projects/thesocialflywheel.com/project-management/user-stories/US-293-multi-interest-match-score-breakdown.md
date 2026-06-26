---
id: US-293
title: "Multi-Interest Match Score Breakdown"
slug: multi-interest-match-score-breakdown
personas: [P-002]
epic: "Swipe-to-Match"
priority: could-have
complexity: medium
tags: [interest-matching, transparency, score, card-layout]
---

# US-293: Multi-Interest Match Score Breakdown

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** expand a swipe card to see a breakdown of how each shared interest contributes to our match score
**So that** I understand why this person was surfaced and whether the overlap is meaningful

## Acceptance Criteria

- **Given** I tap "See why we matched" on a swipe card
  **When** the detail panel opens
  **Then** I see a list of each shared interest with a weight bar showing its relative contribution to the total score

- **Given** the detail panel is open
  **When** I tap a specific interest
  **Then** I am shown a brief blurb about what activity in that interest area was considered (e.g., "Both active in #deep-cuts-cinema this week")
