---
id: US-104
title: "Review and correct time from a phone"
slug: review-and-correct-time-from-phone
personas: [P-001, P-004, P-007]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, mobile]
---

# US-104: Review and correct time from a phone

## User Story

**As a** user who captures on a Mac but reviews on the go
**I want to** open a day's captured spans on my phone and retitle, split, reassign, or mark them non-billable
**So that** I can correct a Mac-captured day without waiting to get back to the desktop

## Acceptance Criteria

- **Given** the Mac captured a span with only a client/project NAME and no resolved id yet
  **When** I pull that span to my phone
  **Then** I see it with its name-based reference intact and can correct it before the server has resolved or vivified the underlying client/project row

- **Given** I retitle a span, split it, or mark it non-billable from the phone while offline
  **When** I reconnect
  **Then** the correction queues and pushes exactly like a Mac-originated edit - the companion performs the same create/update/delete mutations the desktop agent does, not a read-only summary

- **Given** the phone's local copy is stale relative to the server because another device edited the same span more recently
  **When** my edit is evaluated
  **Then** I am shown the server's winning version with a clear "superseded" notice and a one-tap reapply, rather than my edit silently vanishing with no explanation

## Notes

This is the mobile companion's core job (see docs/SYNC-PROTOCOL.md §6 for name-to-id resolution and §7.3 for split/merge/reassign as ordinary mutations). The worked example in §12 (Device B / Android reviewing "on the train") is this story end to end. The third criterion is the conflict-loss case; see US-108 for the honest account of when that loss is permanent rather than just superseded-and-reapplied.
