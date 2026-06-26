---
id: US-014
title: "First-Run Tutorial — Three Lanes Explained"
slug: first-run-tutorial-three-lanes
personas: [P-004, P-006, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [tutorial, lanes, onboarding, UX]
---

# US-014: First-Run Tutorial — Three Lanes Explained

## User Story

**As a** cautious newcomer
**I want to** a brief interactive tutorial that explains the three channel lanes
**So that** I understand how content is organized before I start scrolling

## Acceptance Criteria

- **Given** I complete the interest and connections steps
  **When** I enter a channel for the first time
  **Then** a tooltip overlay highlights the lane switcher tabs (Mutuals / Swipe-to-Match / Opposing Views) with a one-sentence description of each.

- **Given** I tap each tab during the tutorial
  **When** the description is dismissed
  **Then** the tutorial marks that step complete and advances.

## Notes
Tutorial must be completable in under 2 minutes. Offer a "Show me later" option that resurfaces the tutorial on next app open. Never show the same tutorial slide twice.
