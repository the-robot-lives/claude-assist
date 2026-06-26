---
id: US-600
title: "First-Time Engagement Onboarding Tooltip"
slug: first-time-engagement-onboarding
personas: [P-004]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [onboarding, engagement, new-user, tooltip]
---

# US-600: First-Time Engagement Onboarding Tooltip

## User Story

**As a** Cautious Newcomer
**I want to** a brief onboarding guide to engagement features when I first encounter them
**So that** I can learn the platform's rules without reading external documentation

## Acceptance Criteria

- **Given** I view my first post in the Mutuals lane and have not previously used any reaction
  **When** I see the post
  **Then** a one-time tooltip appears on the reaction button explaining "Tap to react; long-press for more options"

- **Given** I view my first post in the Opposing-Views lane
  **Then** a one-time banner explains the read-only rule and why it exists to protect open discourse

- **Given** I dismiss either tooltip
  **Then** it never appears again for my account; tooltip state is persisted server-side not local storage

## Notes
Tooltips must meet WCAG 2.1 AA contrast and be dismissible by keyboard. Do not block interaction while tooltips are visible.
