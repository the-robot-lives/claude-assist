---
id: US-013
title: "Connect Social Accounts to Find Friends"
slug: connect-social-accounts-find-friends
personas: [P-003, P-010]
epic: "Onboarding & Account Setup"
priority: could-have
complexity: high
tags: [social-import, friends, contacts, onboarding]
---

# US-013: Connect Social Accounts to Find Friends

## User Story

**As a** social connector
**I want to** link my existing social accounts
**So that** Flywheel can surface friends who are already using the platform

## Acceptance Criteria

- **Given** I tap "Connect Twitter/X"
  **When** I complete the OAuth flow
  **Then** mutual followers who are on Flywheel appear as suggested connections.

- **Given** I decline to connect any social account
  **When** I tap "Skip"
  **Then** I proceed without any social import and see interest-based suggestions instead.

## Notes
Only friend-list data is read — no posting or timeline access. Third-party tokens are used once for the lookup and not stored. Display the exact permission scope requested before OAuth redirect.
