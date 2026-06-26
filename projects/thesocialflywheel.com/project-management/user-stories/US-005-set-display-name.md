---
id: US-005
title: "Set a Display Name"
slug: set-display-name
personas: [P-004, P-001]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [display-name, profile-setup]
---

# US-005: Set a Display Name

## User Story

**As a** cautious newcomer
**I want to** set a display name separate from my handle
**So that** I can present a friendly name to the community while keeping my real identity private

## Acceptance Criteria

- **Given** I am on the display name screen
  **When** I enter a name of 1–50 characters and continue
  **Then** my display name is saved and shown in the app header.

- **Given** I leave the display name blank
  **When** I try to continue
  **Then** I am prompted that a display name is required.

## Notes
Emoji permitted in display names. Content policy filter runs server-side; flagged names must show a user-friendly message.
