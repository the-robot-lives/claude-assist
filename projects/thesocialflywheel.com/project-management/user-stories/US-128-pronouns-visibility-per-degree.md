---
id: US-128
title: "Control pronouns visibility per degree"
slug: pronouns-visibility-per-degree
personas: [P-004]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, privacy]
---

# US-128: Control Pronouns Visibility Per Degree

## User Story

**As a** cautious newcomer
**I want to** choose which mutual degrees can see my pronouns
**So that** I share identity details only with people close enough in my graph

## Acceptance Criteria

- **Given** I set my pronouns
  **When** I configure their visibility
  **Then** I can choose a minimum degree (e.g. 1st, 2nd) or hide them entirely

- **Given** a viewer is outside my chosen degree
  **When** they view my profile
  **Then** my pronouns are not displayed to them

## Notes
Default to a conservative visibility to protect newcomers.
