---
id: US-679
title: "Report Status Tracking"
slug: report-status-tracking
personas: [P-004]
epic: "Moderation & Reporting"
priority: should-have
complexity: low
tags: [reporting, transparency]
---

# US-679: Report Status Tracking

## User Story

**As a** cautious newcomer who files reports
**I want to** view a "My Reports" list showing the current status of each submission
**So that** I know whether action is being taken and do not need to re-submit the same report

## Acceptance Criteria

- **Given** I navigate to Account Settings > My Reports
  **When** the list loads
  **Then** I see each report I have filed with: reference number, content type reported, date filed, and current status (Submitted / In Review / Resolved / Escalated)

- **Given** a report status changes
  **When** the update occurs
  **Then** a push notification is sent and the My Reports list reflects the new status within 60 seconds

- **Given** a report is resolved with "No action taken"
  **When** I view that entry
  **Then** I see the outcome label and a link to the appeal process in case I disagree

## Notes
Reporter should never see who filed a report alongside theirs or be able to infer other reporters' identities from aggregate counts shown here.
