---
id: US-068
title: "Account Recovery via Support"
slug: account-recovery-support
personas: [P-004]
epic: "Authentication & Security"
priority: should-have
complexity: high
tags: [account-recovery, support, identity-verification]
---

# US-068: Account Recovery via Support

## User Story

**As a** cautious newcomer
**I want to** contact support to recover my account if I have lost all self-service options
**So that** I am not permanently locked out of my account

## Acceptance Criteria

- **Given** I cannot log in and have no working recovery method
  **When** I submit a support recovery request with identity verification information
  **Then** I receive a ticket ID and a response within 72 hours

- **Given** support approves the recovery request
  **When** I follow the emailed recovery steps
  **Then** I can set a new password and re-enroll 2FA

## Notes
Identity verification must not rely solely on information a bad actor could find publicly.
