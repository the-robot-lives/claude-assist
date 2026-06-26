---
id: US-037
title: "Set Degree Visibility Preference"
slug: set-degree-visibility-preference
personas: [P-004, P-006, P-010]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [degrees, visibility, privacy, onboarding]
---

# US-037: Set Degree Visibility Preference

## User Story

**As a** cautious newcomer
**I want to** set the maximum degree of mutuals whose posts appear in my Mutuals lane
**So that** I can control how broad my feed exposure is from the start

## Acceptance Criteria

- **Given** I am on the privacy/visibility setup screen
  **When** I set my degree limit to 2nd
  **Then** only posts from 1st and 2nd-degree moots appear in my Mutuals lane.

- **Given** I later change the degree limit in settings
  **When** the change is saved
  **Then** my feed updates immediately without a full app refresh.

## Notes
Default degree limit is 4th. Degree limit applies only to the Mutuals lane — Opposing Views is unaffected. Explain the trade-off (narrower = fewer posts, broader = more discovery) in the UI.
