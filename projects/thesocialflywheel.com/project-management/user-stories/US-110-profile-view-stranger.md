---
id: US-110
title: "Profile view for a stranger"
slug: profile-view-stranger
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, privacy, safety]
---

# US-110: Profile View for a Stranger

## User Story

**As a** cautious newcomer
**I want** users with no mutual connection to me to see only a minimal profile
**So that** I stay safe and in control of my exposure to people outside my network

## Acceptance Criteria

- **Given** a viewer has no mutual path to me (beyond 4th degree or unconnected)
  **When** they view my profile
  **Then** they see only a minimal card (avatar, display name, optionally pronouns) with bio, links, and interests hidden

- **Given** a stranger later becomes a mutual through matching
  **When** they view my profile again
  **Then** their visibility upgrades to the appropriate degree-based tier

## Notes
Minimal-by-default for strangers supports the safety model (excludes, blocks, dislikes).
