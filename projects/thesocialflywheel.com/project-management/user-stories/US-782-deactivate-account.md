---
id: US-782
title: "Deactivate Account"
slug: deactivate-account
personas: [P-004]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [account, deactivation, safety, reversible]
---

# US-782: Deactivate Account

## User Story

**As a** cautious newcomer
**I want to** temporarily deactivate my account
**So that** my profile and posts are hidden while I take a break, without permanently deleting my data

## Acceptance Criteria

- **Given** I open Account Settings > Account Status
  **When** I choose "Deactivate Account" and confirm
  **Then** my profile becomes invisible to all users, my posts are hidden, and mutual connections no longer see me in their lists.

- **Given** my account is deactivated
  **When** I log back in
  **Then** my account is fully reactivated and all data restored without any additional action required.

## Notes
