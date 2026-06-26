---
id: US-111
title: "Control who can see my full profile"
slug: profile-privacy-controls
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, privacy, identity]
---

# US-111: Control Who Can See My Full Profile

## User Story

**As a** cautious newcomer
**I want to** restrict who can see my full profile based on mutual degree
**So that** only people close to me in the moots graph can view my complete details

## Acceptance Criteria

- **Given** I open my privacy settings
  **When** I set full-profile visibility to "1st-degree mutuals only"
  **Then** users beyond 1st degree see only my limited public card

- **Given** a 3rd-degree mutual visits my profile
  **When** my setting excludes them
  **Then** they see the restricted view and no private fields

- **Given** I change my visibility setting
  **When** I save
  **Then** the new scope applies immediately to subsequent profile views

## Notes
Visibility scopes should map to the degree tiers (1st..4th) plus a public/limited fallback.
