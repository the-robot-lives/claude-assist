---
id: US-767
title: "Configure Dislike Decay"
slug: configure-dislike-decay
personas: [P-005]
epic: "Settings & Preferences"
priority: could-have
complexity: medium
tags: [dislikes, decay, algorithm, content-preferences]
---

# US-767: Configure Dislike Decay

## User Story

**As a** debate seeker
**I want to** configure how quickly my dislike signals decay
**So that** topics I disliked in the past gradually return as my interests evolve.

## Acceptance Criteria

- **Given** I open Content Preferences > Dislikes
  **When** I set decay period to "3 months"
  **Then** content I disliked more than 3 months ago re-enters my feed at low frequency.

- **Given** I set decay to "Never"
  **When** I view disliked content settings
  **Then** all historical dislikes remain active indefinitely until manually removed.

## Notes
Decay options are: 1 month, 3 months, 6 months, 1 year, Never. Default is 6 months.
