---
id: US-722
title: "Batch Similar Notifications to Avoid Overwhelm"
slug: batch-similar-notifications
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [batching, notifications, ux]
---

# US-722: Batch Similar Notifications to Avoid Overwhelm

## User Story

**As a** Quiet Consumer
**I want to** have the same type of notification batched into a single summary during burst activity
**So that** a surge of events does not produce a flood of individual push alerts

## Acceptance Criteria

- **Given** my batching preference is set to "aggressive" (default)
  **When** 3 or more reactions arrive on my post within 5 minutes
  **Then** a single push notification fires: "Your post got [N] reactions in #channel"

- **Given** my batching preference is set to "none"
  **When** reactions arrive
  **Then** each reaction generates an individual notification without grouping

## Notes
Batching applies to reactions, replies, and channel activity. Mentions, DMs, and match alerts are never batched.
