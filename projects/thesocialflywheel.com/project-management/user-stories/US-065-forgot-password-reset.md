---
id: US-065
title: "Forgot Password Email Reset"
slug: forgot-password-reset
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [password-reset, email, recovery]
---

# US-065: Forgot Password Email Reset

## User Story

**As a** cautious newcomer
**I want to** request a password reset link sent to my registered email
**So that** I can regain access if I forget my password

## Acceptance Criteria

- **Given** I click "Forgot password" and enter my email address
  **When** I submit the form
  **Then** I see a confirmation message regardless of whether the email is registered (no enumeration)

- **Given** a valid reset link is emailed to me
  **When** I click the link and set a new password
  **Then** the link is consumed, my password is updated, and all other sessions are invalidated
