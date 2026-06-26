---
id: US-010
title: "Skip Optional Onboarding Steps"
slug: skip-optional-onboarding-steps
personas: [P-006, P-010]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [onboarding, skip, flexibility]
---

# US-010: Skip Optional Onboarding Steps

## User Story

**As a** skeptical switcher
**I want to** be able to skip non-essential onboarding steps
**So that** I can explore the app immediately without being forced through a lengthy setup process

## Acceptance Criteria

- **Given** I am on an optional onboarding step (profile photo, bio, invites)
  **When** I tap "Skip for now"
  **Then** I advance to the next step without saving that step's data.

- **Given** I complete or skip all onboarding steps
  **When** I land on the home screen
  **Then** I see a dismissible onboarding checklist showing what I skipped.

## Notes
Mandatory steps (handle, display name, email verify, ≥3 interests) cannot be skipped. Mark skipped items in the progressive checklist.
