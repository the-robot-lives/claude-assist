---
id: US-059
title: "Deliver messages via mobile push"
slug: deliver-via-push
personas: [P-001]
epic: "Contact Preferences"
priority: wont-have
complexity: high
tags: [delivery, push, mobile, deferred, out-of-scope]
---

# US-059: Deliver messages via mobile push

## User Story

**As a** subscriber who chose mobile push
**I want to** receive push notifications
**So that** I'm alerted on my device

## Acceptance Criteria

- **Given** push is an enabled channel preference
  **When** a message is dispatched
  **Then** it is delivered as a push notification respecting frequency and quiet periods
- **Given** a device token is invalid
  **When** delivery is attempted
  **Then** the token is pruned and the failure recorded
- **Given** a subscriber disables push at the OS level
  **When** delivery is attempted
  **Then** the platform degrades gracefully

## Notes
WON'T-HAVE for M0–M5. Preference stored now; push sender is a later milestone.
Deferred.
