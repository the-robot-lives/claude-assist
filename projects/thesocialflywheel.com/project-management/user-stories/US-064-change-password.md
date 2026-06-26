---
id: US-064
title: "Change Password"
slug: change-password
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [password, account-security, settings]
---

# US-064: Change Password

## User Story

**As a** skeptical switcher
**I want to** change my password from my account security settings
**So that** I can rotate credentials on my own schedule

## Acceptance Criteria

- **Given** I am in Security Settings
  **When** I provide my current password and a new password meeting strength requirements
  **Then** my password is updated, all other sessions are invalidated, and I receive a confirmation email

- **Given** I enter an incorrect current password
  **When** I submit the change-password form
  **Then** the request is rejected and my account's failed-attempt counter increments
