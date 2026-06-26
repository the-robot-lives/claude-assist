---
id: US-360
title: "Discovery Balances Serendipity and Overwhelm"
slug: discovery-balances-serendipity-and-overwhelm
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: high
tags: [discovery, balance, ux]
---

# US-360: Discovery Balances Serendipity and Overwhelm

## User Story

**As a** Quiet Consumer
**I want to** have the discovery engine automatically moderate the novelty level of content it surfaces
**So that** I experience pleasant surprise without feeling bombarded by unfamiliar topics

## Acceptance Criteria

- **Given** I have engaged with fewer than three discovery items in the past week
  **When** the engine selects discovery items for my next session
  **Then** it limits the number of distinct new topic clusters to two or fewer

- **Given** I have engaged positively with many discovery items recently
  **When** the engine selects items for my next session
  **Then** it may introduce up to four distinct topic clusters to match my demonstrated appetite

## Notes
The engine should treat low engagement as a signal of overwhelm, not disinterest, before reducing volume.
