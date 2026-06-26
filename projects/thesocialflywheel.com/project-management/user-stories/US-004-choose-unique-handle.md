---
id: US-004
title: "Choose a Unique Handle"
slug: choose-unique-handle
personas: [P-004, P-009]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [handle, username, profile-setup]
---

# US-004: Choose a Unique Handle

## User Story

**As a** new user
**I want to** pick a unique @handle
**So that** others can mention and find me by a memorable name of my choosing

## Acceptance Criteria

- **Given** I type a handle
  **When** I pause typing
  **Then** the app checks availability in real time and shows a green checkmark or "taken" indicator within 500 ms.

- **Given** my chosen handle is taken
  **When** I submit
  **Then** the app suggests three available variants (e.g. append numbers or underscores) with one-tap adoption.

## Notes
Handles: 3–30 characters, alphanumeric + underscores only. Case-insensitive uniqueness check. Reserved words blocked.
