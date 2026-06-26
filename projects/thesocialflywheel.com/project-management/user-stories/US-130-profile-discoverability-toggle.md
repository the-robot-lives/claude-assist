---
id: US-130
title: "Toggle profile discoverability in search"
slug: profile-discoverability-toggle
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, privacy, discovery]
---

# US-130: Toggle Profile Discoverability In Search

## User Story

**As a** cautious newcomer
**I want to** control whether my profile appears in search and discovery
**So that** I decide how findable I am beyond my existing mutuals

## Acceptance Criteria

- **Given** I open privacy settings
  **When** I disable search visibility
  **Then** my profile no longer surfaces in search or rotation for non-mutuals

- **Given** discoverability is disabled
  **When** an existing mutual looks me up
  **Then** they can still find and reach me

## Notes
Discoverability is independent of lane visibility; both apply together.
