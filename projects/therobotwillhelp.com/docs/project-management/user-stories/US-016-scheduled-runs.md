---
id: US-016
title: "Schedule recurring robot runs"
slug: scheduled-runs
personas: [P-001, P-004]
epic: "Scheduling"
priority: could-have
complexity: medium
tags: [scheduler, recurrence, repeatable-work]
---

# US-016: Schedule recurring robot runs

## User Story

**As a** founder-operator  
**I want to** schedule recurring runs with timezone-aware windows  
**So that** routine work happens reliably without manual triggers.

## Acceptance Criteria

- **Given** a workflow supports schedules, **When** I set a weekly run, **Then** it appears in the active calendar.
- **Given** a scheduled run executes, **When** it fails, **Then** escalation follows the configured fallback policy.

