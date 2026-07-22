---
id: US-087
title: "Notification preferences"
slug: "notification-preferences"
personas: [P-006, P-004]
epic: "Settings & Localization"
priority: "could-have"
complexity: "S"
tags: [localization, settings, notifications]
---

# US-087: Notification preferences

## User Story

**As a** bookkeeper (P-006),
**I want to** choose which notifications I receive (low stock, daily cash-up summary, sync issues),
**So that** I'm alerted to what matters without being overwhelmed by noise.

## Acceptance Criteria

- [ ] Given Settings > Notifications, when the user toggles individual categories (low stock, daily summary, sync errors) on or off, then only enabled categories generate push notifications going forward.
- [ ] Given a user has "daily cash-up summary" enabled, when the store closes for the day (or at a configured time), then a summary notification is sent once, not duplicated across devices for the same store.
- [ ] Given a critical alert type (e.g., "sync failed for 48 hours"), when notifications are otherwise disabled, then that critical category still notifies the owner by default unless explicitly muted.

## Notes

Could-have — useful for multi-store/bookkeeper roles (P-004, P-006) but not required for a single-owner v1 launch.
