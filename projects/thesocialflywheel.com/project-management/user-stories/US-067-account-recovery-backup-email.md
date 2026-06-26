---
id: US-067
title: "Account Recovery via Backup Email"
slug: account-recovery-backup-email
personas: [P-004]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [account-recovery, email, security]
---

# US-067: Account Recovery via Backup Email

## User Story

**As a** cautious newcomer
**I want to** add a backup email address for account recovery
**So that** I can regain access even if I lose access to my primary email

## Acceptance Criteria

- **Given** I add and verify a backup email in Security Settings
  **When** I trigger account recovery and choose "use backup email"
  **Then** a recovery link is sent to my backup email address

- **Given** my backup email has not been verified
  **When** I attempt to use it for recovery
  **Then** I am informed it cannot be used until verified
