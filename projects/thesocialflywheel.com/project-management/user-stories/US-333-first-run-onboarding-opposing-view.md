---
id: US-333
title: "First-Run Onboarding for Opposing-View Concept"
slug: first-run-onboarding-opposing-view
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, onboarding, education, first-run]
---

# US-333: First-Run Onboarding for Opposing-View Concept

## User Story

**As a** cautious newcomer
**I want to** receive a short onboarding flow that explains the Opposing-Views Lane before I encounter it
**So that** I can make an informed choice about whether to engage with the feature at all

## Acceptance Criteria

- **Given** I have just completed account setup
  **When** the onboarding wizard reaches the feed configuration step
  **Then** a screen explains the Opposing-Views Lane with a visual example and an option to enable, reduce, or skip it

- **Given** I choose to skip the lane during onboarding
  **When** onboarding completes
  **Then** the lane is disabled by default and I can enable it later from Feed Settings

## Notes
The onboarding screen must not be skippable without making an explicit choice (enable / reduce / skip). A "decide later" option counts as skip.
