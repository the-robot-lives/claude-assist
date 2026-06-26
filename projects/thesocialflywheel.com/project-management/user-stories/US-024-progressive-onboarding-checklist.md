---
id: US-024
title: "Progressive Onboarding Checklist"
slug: progressive-onboarding-checklist
personas: [P-004, P-003, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [checklist, onboarding, progress, engagement]
---

# US-024: Progressive Onboarding Checklist

## User Story

**As a** cautious newcomer
**I want to** a persistent but dismissible onboarding checklist
**So that** I can complete setup at my own pace and know exactly what is left to do

## Acceptance Criteria

- **Given** I complete the initial signup flow
  **When** I reach the home screen
  **Then** a checklist widget shows my progress (e.g. "3 of 7 steps complete") with unchecked items listed.

- **Given** I complete a checklist item at any point in the app
  **When** I return to the checklist
  **Then** that item is marked complete with an animation and the progress counter updates.

## Notes
Checklist items: verify email, add photo, pick 3+ interests, find 1 moot, complete 3-lane tutorial, set privacy, post in a channel. Checklist collapses after all items done. "Dismiss forever" option available after 50% complete.
