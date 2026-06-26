---
id: US-286
title: "Moot-of-Moot Weighting After Match"
slug: moot-of-moot-weighting-after-match
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: high
tags: [mutuals, graph, ranking, moot-of-moot]
---

# US-286: Moot-of-Moot Weighting After Match

## User Story

**As a** Bridge-Builder (P-001)
**I want to** have my new mutual's connections automatically factored into my feed and swipe queue as degree-2 candidates
**So that** each match meaningfully expands my discovery network

## Acceptance Criteria

- **Given** I accept an incoming interest and we become mutuals
  **When** the ranking service next processes my graph
  **Then** the new mutual's degree-1 connections appear as weighted degree-2 candidates in my Swipe-to-Match queue

- **Given** a degree-2 candidate is surfaced via moot-of-moot weighting
  **When** their card is shown
  **Then** the card indicates "Mutual of [shared mutual's display name]" as context
