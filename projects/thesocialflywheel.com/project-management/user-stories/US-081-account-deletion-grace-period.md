---
id: US-081
title: "Account Deletion Grace Period Cancellation"
slug: account-deletion-grace-period
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [account-deletion, recovery, grace-period]
---

# US-081: Account Deletion Grace Period Cancellation

## User Story

**As a** cautious newcomer
**I want to** cancel my account deletion request within the 14-day grace period
**So that** I can change my mind without losing my account

## Acceptance Criteria

- **Given** I have submitted an account deletion request
  **When** I log in within the 14-day grace period
  **Then** I see a prominent banner informing me of the pending deletion with a "Cancel deletion" button

- **Given** I click "Cancel deletion" and confirm
  **When** the cancellation is processed
  **Then** the deletion request is voided and my account continues normally
