---
id: US-668
title: "Moderator Audit Log"
slug: moderator-audit-log
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, audit, transparency]
---

# US-668: Moderator Audit Log

## User Story

**As a** channel moderator or owner
**I want to** view a tamper-evident log of every moderation action taken in my channel
**So that** I can verify accountability and investigate disputes about mod behaviour

## Acceptance Criteria

- **Given** I open the channel Audit Log
  **When** the log loads
  **Then** each entry shows: action type, acting mod's display name, target user/content, reason cited, timestamp, and outcome (including any subsequent appeal result)

- **Given** the audit log contains entries
  **When** I apply filters (by mod, action type, or date range)
  **Then** the log updates to show only matching entries without losing entries outside the filter

- **Given** I need a record for external review
  **When** I click "Export"
  **Then** a CSV is generated containing all visible log entries with the same fields

## Notes
Audit log entries must be immutable once written; no mod (including the owner) should be able to delete or edit an entry.
