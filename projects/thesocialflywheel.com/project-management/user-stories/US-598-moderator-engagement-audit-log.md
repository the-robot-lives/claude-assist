---
id: US-598
title: "Review Engagement Audit Log as Moderator"
slug: moderator-engagement-audit-log
personas: [P-007]
epic: "Reactions & Engagement"
priority: should-have
complexity: high
tags: [moderation, audit, transparency]
---

# US-598: Review Engagement Audit Log as Moderator

## User Story

**As a** Channel Moderator
**I want to** access an engagement audit log for my channel
**So that** I can investigate patterns of abuse and take targeted action

## Acceptance Criteria

- **Given** I open Moderator Tools → Audit Log and filter by "Reactions"
  **Then** I see a time-sorted list of all reactions and their authors for the last 30 days within my channel

- **Given** I select a log entry
  **When** I click "Flag for review"
  **Then** the engagement is queued in the trust-and-safety dashboard with moderator context attached

## Notes
Audit log retains data for 90 days. CSV export available for channels with more than 1,000 members. Log access is restricted to channel moderators and above.
