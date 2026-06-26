---
id: US-713
title: "Receive Weekly Activity Digest Email"
slug: weekly-digest-email
personas: [P-006]
epic: "Notifications"
priority: could-have
complexity: medium
tags: [email, digest, notifications, low-frequency]
---

# US-713: Receive Weekly Activity Digest Email

## User Story

**As a** Quiet Consumer
**I want to** opt into a weekly digest email instead of daily
**So that** I receive a higher-signal, lower-noise summary that respects my preference for minimal interruption

## Acceptance Criteria

- **Given** I have set my digest frequency to "weekly"
  **When** the weekly digest job runs on my configured day and time
  **Then** I receive a curated email covering: new mutual connections, channel highlights, top posts from my network, and my own post engagement summary

- **Given** I am subscribed to weekly digest and also have daily digest enabled
  **When** the weekly digest runs
  **Then** daily digests are suppressed for that week; only the weekly digest is sent

## Notes
Weekly digest should include a "Weekly Roundup" header visually distinguishing it from daily digests.
