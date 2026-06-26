---
id: US-077
title: "Account Lockout After Failed Attempts"
slug: account-lockout-after-failures
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [lockout, security, brute-force]
---

# US-077: Account Lockout After Failed Attempts

## User Story

**As a** cautious newcomer
**I want to** have my account temporarily locked after many failed login attempts
**So that** someone guessing my password is blocked even if they use different IPs

## Acceptance Criteria

- **Given** 10 consecutive failed login attempts for my email address
  **When** the 10th failure occurs
  **Then** the account is locked for 15 minutes and I receive an email notification

- **Given** my account is locked
  **When** I receive the lockout email
  **Then** the email contains a link to immediately unlock via verified email if the attempts were not mine
