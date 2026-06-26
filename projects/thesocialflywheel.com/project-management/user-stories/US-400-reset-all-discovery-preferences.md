---
id: US-400
title: "Reset All Discovery Preferences"
slug: reset-all-discovery-preferences
personas: [P-005]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, settings, reset]
---

# US-400: Reset All Discovery Preferences

## User Story

**As a** Debate Seeker
**I want to** reset all my discovery preferences and signals to their defaults in a single action
**So that** I can start fresh when I feel my accumulated signals no longer reflect my current interests

## Acceptance Criteria

- **Given** I navigate to Discovery Settings
  **When** I tap "Reset All Discovery Preferences" and confirm the action in the confirmation dialog
  **Then** all topic weights, exclusion lists, cooldowns, volume settings, and serendipity toggles are cleared and restored to defaults

- **Given** my discovery preferences have been reset
  **When** my feed next loads
  **Then** discovery behaves as if I am a user who has just completed the onboarding interest quiz, with no accumulated signals influencing item selection

## Notes
Reset is irreversible and must be confirmed with a two-step dialog warning the user that exclusion lists and cooldowns will be cleared. It does not affect the social graph or follow relationships.
