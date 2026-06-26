---
id: US-365
title: "Cold-Start Discovery for New Account"
slug: cold-start-discovery-for-new-account
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: high
tags: [discovery, cold-start, onboarding]
---

# US-365: Cold-Start Discovery for New Account

## User Story

**As a** Bridge-Builder
**I want to** receive discovery content immediately after signing up even before I have mutuals
**So that** my feed is not empty and I can start finding channels and people to connect with

## Acceptance Criteria

- **Given** I am a new user with zero mutuals and have completed the interest quiz
  **When** I open my feed for the first time
  **Then** discovery items seeded from my stated interests are shown, drawn from publicly visible popular posts in those interest areas within the global network

- **Given** I am in cold-start mode
  **When** I follow my first mutual
  **Then** the cold-start content is progressively replaced by graph-sourced discovery over the next feed refresh

## Notes
Cold-start content must still respect content safety rules even though no graph boundary applies yet. Limit to top-level channels and staff-curated posts.
