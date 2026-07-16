---
id: US-012
title: "Review Past Session Logs"
slug: review-past-session-logs
personas: [P-002, P-004]
epic: "Knowledge Base"
priority: should-have
complexity: low
tags: [session-log, review, retrospective]
---

# US-012: Review Past Session Logs

## User Story

**As a** developer preparing for a review or interview
**I want to** review past session logs to retrace what I learned
**So that** I can refresh my memory on topics I've already studied

## Acceptance Criteria

- **Given** I have prior session logs
  **When** I run the session-log review command
  **Then** I can list sessions by date range or topic

- **Given** I select a specific session log
  **When** I view it
  **Then** I see the questions asked and links to the resulting knowledge articles

- **Given** I search session logs by keyword
  **When** a match is found
  **Then** the matching sessions are surfaced with the relevant excerpt highlighted

## Notes
Depends on US-011's session log format being consistently written.
