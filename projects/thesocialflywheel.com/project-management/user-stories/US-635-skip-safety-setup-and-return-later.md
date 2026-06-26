---
id: US-635
title: "Skip Safety Setup and Return Later"
slug: skip-safety-setup-and-return-later
personas: [P-010]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: low
tags: [safety, onboarding]
---

# US-635: Skip Safety Setup and Return Later

## User Story

**As a** skeptical switcher
**I want to** skip the onboarding safety wizard and come back to it later
**So that** I am not forced to make safety decisions before I understand the platform

## Acceptance Criteria

- **Given** I am on the safety wizard step in onboarding
  **When** I tap "Skip for now"
  **Then** onboarding continues and safe defaults are applied automatically

- **Given** I have skipped safety setup
  **When** I visit Settings > Safety for the first time
  **Then** a highlighted banner reads "Complete your safety setup" with a link back to the wizard flow

## Notes
The banner persists until the user explicitly dismisses it or completes setup.
