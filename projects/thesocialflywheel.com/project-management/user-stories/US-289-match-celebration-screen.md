---
id: US-289
title: "Match Celebration Screen"
slug: match-celebration-screen
personas: [P-003]
epic: "Swipe-to-Match"
priority: could-have
complexity: low
tags: [delight, match, onboarding, animation]
---

# US-289: Match Celebration Screen

## User Story

**As a** Social Connector (P-003)
**I want to** see a celebratory moment when a match is confirmed
**So that** the milestone of becoming mutuals feels meaningful and rewarding

## Acceptance Criteria

- **Given** I accept an interest and we become mutuals
  **When** the acceptance is confirmed
  **Then** a brief celebration overlay appears with both display names and a "You're now mutuals!" message before auto-dismissing after 3 seconds

- **Given** the user has "Reduce Motion" enabled
  **When** the celebration overlay appears
  **Then** it displays as a static banner with no particle or confetti animation
