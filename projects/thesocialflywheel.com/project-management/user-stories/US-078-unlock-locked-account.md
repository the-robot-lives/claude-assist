---
id: US-078
title: "Unlock a Locked Account"
slug: unlock-locked-account
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [lockout, account-recovery, security]
---

# US-078: Unlock a Locked Account

## User Story

**As a** cautious newcomer
**I want to** unlock my account via an email link when I am locked out due to failed attempts
**So that** I can regain access immediately if the failed attempts were mine

## Acceptance Criteria

- **Given** my account is locked
  **When** I click the unlock link in the lockout notification email from my verified device
  **Then** the lock is removed and I am prompted to log in normally

- **Given** the lockout period expires naturally (15 minutes)
  **When** I attempt to log in again
  **Then** I can log in without needing to use the email link
