---
id: US-090
title: "Moderator-Triggered Forced Password Reset"
slug: moderator-forced-password-reset
personas: [P-007]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [moderator, password-reset, account-security]
---

# US-090: Moderator-Triggered Forced Password Reset

## User Story

**As a** channel moderator with platform admin escalation
**I want to** flag an account for a forced password reset
**So that** a compromised account can be secured before further harm is done in my channel

## Acceptance Criteria

- **Given** I identify a potentially compromised account through unusual posting behavior
  **When** I submit a forced-reset request with a reason
  **Then** the account is suspended from posting and the user receives a mandatory password reset email

- **Given** the user completes the forced password reset
  **When** they set a new password
  **Then** all existing sessions are invalidated, the posting suspension is lifted, and the moderator action is logged
