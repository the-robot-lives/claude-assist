---
id: US-026
title: "Abandoned Signup Recovery via Email"
slug: abandoned-signup-recovery-email
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [recovery, abandoned-signup, email, re-onboarding]
---

# US-026: Abandoned Signup Recovery via Email

## User Story

**As a** someone who started signing up but did not finish
**I want to** receive a recovery email
**So that** I can resume my account setup without starting from scratch

## Acceptance Criteria

- **Given** I entered a valid email and moved past step 1 but did not complete signup
  **When** 24 hours pass
  **Then** I receive a single recovery email with a "Continue your setup" deep link.

- **Given** I click the deep link
  **When** the app opens
  **Then** I am returned to the exact onboarding step where I stopped with my previous entries pre-filled.

## Notes
Send at most one recovery email per abandoned session. Honor unsubscribe. Do not send if the user completed signup on a different device in the interim.
