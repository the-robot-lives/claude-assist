---
id: US-012
title: "Suggested Connections Based on Interests"
slug: suggested-connections-based-on-interests
personas: [P-004, P-001, P-003]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [suggestions, mutuals, interests, onboarding]
---

# US-012: Suggested Connections Based on Interests

## User Story

**As a** cautious newcomer
**I want to** see suggested accounts that share my interests
**So that** I can start building a mutuals web even without importing contacts

## Acceptance Criteria

- **Given** I have selected at least 3 interests
  **When** I reach the "Find People" step
  **Then** I see at least 10 suggested profiles ranked by shared interests.

- **Given** I send a mutual request
  **When** the other user accepts
  **Then** they become a 1st-degree moot and their posts appear in my Mutuals lane.

## Notes
Suggestions should avoid surfacing users who blocked the current user. Include a "Not interested" dismiss per suggestion that improves future recommendations.
