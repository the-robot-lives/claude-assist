---
id: US-783
title: "Delete Account"
slug: delete-account
personas: [P-010]
epic: "Settings & Preferences"
priority: must-have
complexity: high
tags: [account, deletion, gdpr, irreversible]
---

# US-783: Delete Account

## User Story

**As a** skeptical switcher
**I want to** permanently delete my account and all associated data
**So that** Flywheel Social retains no personal information about me

## Acceptance Criteria

- **Given** I open Account Settings > Account Status
  **When** I select "Delete Account" and pass the two-step confirmation (type handle + enter password)
  **Then** account deletion is scheduled and a confirmation email is sent.

- **Given** deletion is scheduled
  **When** the 14-day grace period expires without cancellation
  **Then** all personal data (profile, posts, messages, mutual links) is permanently erased and the handle is released.

## Notes
During the grace period the account is deactivated but not deleted; the user may cancel by logging in.
