---
id: US-784
title: "Cancel Account Deletion During Grace Period"
slug: cancel-account-deletion-during-grace-period
personas: [P-004]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [account, deletion, grace-period, safety]
---

# US-784: Cancel Account Deletion During Grace Period

## User Story

**As a** cautious newcomer
**I want to** cancel a pending account deletion during the grace period
**So that** I can change my mind without losing my account

## Acceptance Criteria

- **Given** my account deletion is scheduled and within the 14-day grace period
  **When** I log in and click "Cancel Deletion"
  **Then** the deletion is cancelled, my account is reactivated, and I receive a confirmation email.

## Notes
