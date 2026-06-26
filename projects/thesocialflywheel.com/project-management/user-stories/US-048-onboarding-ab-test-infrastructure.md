---
id: US-048
title: "Onboarding A/B Test Infrastructure"
slug: onboarding-ab-test-infrastructure
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: could-have
complexity: high
tags: [ab-testing, onboarding, experimentation, engineering]
---

# US-048: Onboarding A/B Test Infrastructure

## User Story

**As a** product team member
**I want to** the onboarding flow to support A/B experiment assignments at the step level
**So that** we can measure which flows drive higher completion and day-7 retention

## Acceptance Criteria

- **Given** a new user starts onboarding
  **When** the flow initialises
  **Then** an experiment bucket (control or variant) is assigned deterministically and logged with the user's account.

- **Given** the user completes or abandons onboarding
  **When** the event fires
  **Then** the experiment bucket, completed steps, and time-per-step are included in the analytics payload.

## Notes
Experiment config loaded from remote feature flags (no deploy required for new tests). Users should never switch buckets mid-onboarding. This is an infrastructure story — acceptance tested by the analytics pipeline, not the UI.
