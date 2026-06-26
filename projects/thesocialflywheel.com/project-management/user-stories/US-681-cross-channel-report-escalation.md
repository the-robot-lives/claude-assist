---
id: US-681
title: "Cross-Channel Report Escalation"
slug: cross-channel-report-escalation
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [moderation, escalation, cross-channel]
---

# US-681: Cross-Channel Report Escalation

## User Story

**As a** platform Trust & Safety reviewer
**I want to** be automatically alerted when the same user accumulates reports across multiple channels
**So that** I can assess platform-wide patterns that individual channel mods cannot see

## Acceptance Criteria

- **Given** a user receives substantiated reports (i.e. action taken) in three or more distinct channels within 30 days
  **When** the third report is resolved with action
  **Then** a consolidated cross-channel case is auto-created in the platform T&S queue containing links to all contributing channel cases

- **Given** the consolidated case exists
  **When** a platform T&S reviewer opens it
  **Then** they see a timeline of all cross-channel incidents, the channels involved, and the actions taken by each channel's mod team

- **Given** I apply a global sanction via the consolidated case
  **When** the sanction is saved
  **Then** all contributing channel mods are notified of the platform-level action via their mod notification centre

## Notes
Cross-channel rollup should only count cases where action was taken, not dismissed reports, to prevent gaming via filing false reports.
