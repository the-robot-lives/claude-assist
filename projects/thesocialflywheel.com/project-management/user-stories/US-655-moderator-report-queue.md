---
id: US-655
title: "Moderator Report Queue"
slug: moderator-report-queue
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, queue]
---

# US-655: Moderator Report Queue

## User Story

**As a** channel moderator
**I want to** view a prioritised list of all open reports for my channel
**So that** I can work through the most urgent cases first without missing anything

## Acceptance Criteria

- **Given** I open the Moderation panel for my channel
  **When** the report queue loads
  **Then** I see each report with: reporter-count, reason category, content snippet, time since first report, and current status (new / in review / resolved)

- **Given** the queue contains reports
  **When** they are displayed
  **Then** they are sorted by default with CSAM/Self-harm at top, then highest report-count, then oldest unactioned

## Notes
Mods should only see reports for channels where they hold a mod role; cross-channel data must not be exposed.
