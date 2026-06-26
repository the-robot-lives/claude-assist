---
id: US-061
title: "Backup Codes for 2FA Recovery"
slug: backup-codes-for-2fa
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [2fa, backup-codes, recovery]
---

# US-061: Backup Codes for 2FA Recovery

## User Story

**As a** cautious newcomer
**I want to** generate and store one-time backup codes when I enable 2FA
**So that** I can regain access if I lose my second factor device

## Acceptance Criteria

- **Given** I complete 2FA setup
  **When** the setup wizard finishes
  **Then** I am shown 10 single-use backup codes and prompted to download or print them

- **Given** I use a backup code to log in
  **When** authentication succeeds
  **Then** that code is invalidated and I am warned that I have fewer remaining codes
