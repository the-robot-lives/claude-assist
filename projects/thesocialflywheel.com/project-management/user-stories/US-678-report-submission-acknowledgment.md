---
id: US-678
title: "Report Submission Acknowledgment"
slug: report-submission-acknowledgment
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [reporting, ux, notifications]
---

# US-678: Report Submission Acknowledgment

## User Story

**As a** cautious newcomer who has just submitted a report
**I want to** receive an immediate confirmation with a reference number
**So that** I know the report was received and can follow up if needed

## Acceptance Criteria

- **Given** I submit a report of any type (post, profile, channel, DM)
  **When** the report is saved
  **Then** an in-app toast notification appears within 2 seconds confirming receipt and showing a human-readable reference number (e.g. RPT-20240412-7823)

- **Given** the acknowledgment is shown
  **When** I navigate away
  **Then** the same reference number is available in my "My Reports" list under my account settings

## Notes
Reference numbers help users follow up with support and make it harder to claim a report was never filed.
