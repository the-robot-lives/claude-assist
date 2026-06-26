---
id: US-751
title: "Change Email Address"
slug: change-email-address
personas: [P-010]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [settings, account, email]
---

# US-751: Change Email Address

## User Story

**As a** skeptical switcher
**I want to** update my email address in account settings
**So that** I can keep my contact information current without losing my account history.

## Acceptance Criteria

- **Given** I am on the Account Settings page
  **When** I enter a new valid email and click Save
  **Then** a verification link is sent to the new address and my email is updated only after I confirm it.

- **Given** I have entered a new email
  **When** I do not confirm within 48 hours
  **Then** the change is cancelled and my original email remains active.

## Notes
Email changes require confirmation to prevent accidental or malicious address replacement. The 48-hour window balances convenience with security.
