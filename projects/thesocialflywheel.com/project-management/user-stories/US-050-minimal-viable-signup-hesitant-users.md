---
id: US-050
title: "Minimal Viable Signup for Hesitant Users"
slug: minimal-viable-signup-hesitant-users
personas: [P-010, P-006, P-004]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [minimal, signup, friction-reduction, onboarding]
---

# US-050: Minimal Viable Signup for Hesitant Users

## User Story

**As a** skeptical switcher
**I want to** be able to create an account with the bare minimum information (email + password + 3 interests) and explore before committing to full profile setup
**So that** I can evaluate Flywheel before investing time in setup

## Acceptance Criteria

- **Given** I choose "Quick signup" on the landing screen
  **When** I provide only email, password, and 3 interests and submit
  **Then** a basic account is created and I land on a channels view immediately.

- **Given** I am in the minimal account state
  **When** I attempt an action requiring a complete profile (e.g. sending a mutual request)
  **Then** I am shown an inline nudge to complete that specific profile field, not a full-screen onboarding interrupt.

## Notes
"Quick signup" skips: photo, bio, contacts, social import, tutorial, notification prefs. These surface through the progressive checklist at the user's pace. Handle is auto-generated from email prefix and can be changed later.
