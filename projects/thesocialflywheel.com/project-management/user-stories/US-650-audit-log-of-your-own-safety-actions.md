---
id: US-650
title: "Audit Log of Your Own Safety Actions"
slug: audit-log-of-your-own-safety-actions
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, audit, management]
---

# US-650: Audit Log of Your Own Safety Actions

## User Story

**As a** cautious newcomer
**I want to** view a chronological log of all safety actions I have taken (blocks, mutes, exclusions, reports)
**So that** I can review my own history, understand patterns, and verify actions were applied correctly

## Acceptance Criteria

- **Given** I navigate to Settings > Safety > Activity Log
  **When** the page loads
  **Then** I see a time-ordered list of safety events: action type, target (user or tag), date, and current status (active / reversed)

- **Given** an action in the log has been reversed (e.g., an unblock)
  **When** I view that entry
  **Then** it shows both the original action date and the reversal date with distinct labels

- **Given** the audit log contains more than 50 entries
  **When** I scroll to the bottom
  **Then** older entries load via pagination or infinite scroll without losing my position

## Notes
The log is private to the account owner; it is not shared with other users or visible to admins under normal circumstances (see US-648).
