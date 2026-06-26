---
id: US-082
title: "Account Reactivation After Deletion"
slug: account-reactivation
personas: [P-010]
epic: "Authentication & Security"
priority: could-have
complexity: medium
tags: [account-reactivation, recovery]
---

# US-082: Account Reactivation After Deletion

## User Story

**As a** skeptical switcher
**I want to** reactivate my recently deleted account by logging in within a short window
**So that** accidental or regretted deletions can be undone without creating a new account

## Acceptance Criteria

- **Given** my account was deleted within the last 30 days
  **When** I log in with my previous credentials
  **Then** I am shown an option to reactivate my account and restore available data

- **Given** more than 30 days have passed since deletion
  **When** I try to log in with old credentials
  **Then** I receive an error and am offered the option to create a new account
