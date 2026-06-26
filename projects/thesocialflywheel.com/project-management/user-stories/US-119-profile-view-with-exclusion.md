---
id: US-119
title: "Filter profile view when an exclusion applies"
slug: profile-view-with-exclusion
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, safety, interests]
---

# US-119: Filter Profile View When An Exclusion Applies

## User Story

**As a** cautious newcomer
**I want to** have my interest/belief exclusions respected when others view my profile
**So that** I am not surfaced or matched around topics I chose to avoid

## Acceptance Criteria

- **Given** I excluded a specific interest or belief
  **When** another user views my profile
  **Then** that excluded interest/belief is not displayed on my profile

- **Given** a viewer's profile centers on an interest I excluded
  **When** they view my profile
  **Then** that interest is not presented as shared or as a connection point

## Notes
Exclusions are symmetric inputs to shared-interest and discovery computations.
