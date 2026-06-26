---
id: US-041
title: "Set Bio or Tagline During Onboarding"
slug: set-bio-tagline-onboarding
personas: [P-009, P-003, P-004]
epic: "Onboarding & Account Setup"
priority: could-have
complexity: low
tags: [bio, profile, onboarding]
---

# US-041: Set Bio or Tagline During Onboarding

## User Story

**As a** creator
**I want to** write a short bio or tagline during setup
**So that** people who discover me through interest channels understand what I am about before deciding to moot me

## Acceptance Criteria

- **Given** I am on the bio step
  **When** I type up to 160 characters and tap continue
  **Then** the bio is saved and displayed on my profile card in suggested connections.

- **Given** I skip the bio step
  **When** others view my profile
  **Then** the bio field shows "No bio yet" with an edit prompt visible only to me.

## Notes
Bio is plain text only during onboarding — rich formatting can be added from profile settings later. Run content policy filter server-side asynchronously.
