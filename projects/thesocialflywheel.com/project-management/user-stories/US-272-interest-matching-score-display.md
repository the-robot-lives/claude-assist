---
id: US-272
title: "Interest Matching Score Display"
slug: interest-matching-score-display
personas: [P-002]
epic: "Swipe-to-Match"
priority: could-have
complexity: medium
tags: [interest-matching, score, transparency, card-layout]
---

# US-272: Interest Matching Score Display

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** see a visual compatibility indicator on a swipe card
**So that** I can quickly gauge how strong the shared-interest overlap is before reading the details

## Acceptance Criteria

- **Given** an interest overlap score has been computed for a candidate
  **When** their card is displayed
  **Then** a percentage or bar indicator shows the relative strength of our interest alignment

- **Given** I tap the compatibility indicator
  **When** the detail popover opens
  **Then** it lists each shared interest with its individual weight contribution to the overall score
