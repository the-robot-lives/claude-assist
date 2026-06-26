---
id: US-677
title: "Bulk Mod Actions on Queue"
slug: bulk-mod-actions-on-queue
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [moderation, queue, bulk-actions]
---

# US-677: Bulk Mod Actions on Queue

## User Story

**As a** channel moderator handling a spam wave
**I want to** select multiple report cards and apply the same action in one step
**So that** I can clear coordinated spam efficiently without repeating the same action dozens of times

## Acceptance Criteria

- **Given** the report queue contains multiple spam or duplicate reports
  **When** I check the checkbox on three or more report cards
  **Then** a bulk-action toolbar appears offering: Dismiss All, Remove Content, Warn All Authors

- **Given** I apply a bulk action
  **When** the action runs
  **Then** each affected report is individually logged in the audit trail with "bulk action" noted alongside my display name and timestamp

- **Given** one of the selected reports has already been claimed by another mod
  **When** I attempt a bulk action including it
  **Then** a warning is shown listing the conflicting report; I can proceed excluding it or cancel

## Notes
Bulk ban is intentionally excluded from the initial scope; banning multiple users simultaneously is a high-stakes action that warrants individual review.
