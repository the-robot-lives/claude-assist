---
id: US-080
title: "Account Deletion Request"
slug: account-deletion-request
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [account-deletion, privacy, gdpr]
---

# US-080: Account Deletion Request

## User Story

**As a** cautious newcomer
**I want to** request deletion of my account and all associated data
**So that** I can leave the platform and know my information is removed

## Acceptance Criteria

- **Given** I navigate to Account Settings
  **When** I initiate account deletion and re-authenticate with my password
  **Then** I am shown what data will be deleted, given a 14-day grace period, and shown a confirmation screen

- **Given** I confirm the deletion request
  **When** the request is submitted
  **Then** I receive an email confirming the deletion schedule and a cancellation link valid for 14 days
