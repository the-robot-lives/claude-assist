---
id: US-673
title: "Brigading and Coordinated Abuse Detection"
slug: brigading-coordinated-abuse-detection
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: high
tags: [moderation, brigading, coordinated-abuse]
---

# US-673: Brigading and Coordinated Abuse Detection

## User Story

**As a** channel moderator
**I want to** be alerted when multiple accounts appear to be coordinating reports against the same user or post
**So that** I can discount brigading pressure and focus on genuine community reports

## Acceptance Criteria

- **Given** multiple reports on the same target arrive within a short window
  **When** the system detects that more than 5 of those reporters joined the platform or this channel in the same 48-hour cohort
  **Then** the report cluster is flagged "Possible brigading" and its weight is not added to the auto-hide threshold count

- **Given** a brigading flag is raised
  **When** I view the flagged report cluster
  **Then** I see a summary showing the cohort overlap, join dates, and originating posts that likely drove the coordinated reports

- **Given** I review the brigading flag and determine it is a false positive
  **When** I dismiss the flag
  **Then** the reports are re-weighted normally and the queue position updates accordingly

## Notes
Brigading detection heuristics should be tunable by platform T&S without a code deploy.
