---
id: US-651
title: "Report a Post"
slug: report-a-post
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [reporting, reporter-flow]
---

# US-651: Report a Post

## User Story

**As a** cautious newcomer
**I want to** report an offensive or rule-breaking post with a few taps
**So that** the channel moderator can review it without my identity being revealed to the poster

## Acceptance Criteria

- **Given** I am viewing a post in any channel
  **When** I tap the "…" overflow menu and select "Report"
  **Then** a reason-selection sheet appears and my report is submitted without the poster being notified of my identity

- **Given** I have submitted a report
  **When** the report is received
  **Then** I see an in-app confirmation and receive a notification with a report reference number

## Notes
Reporter identity must never appear in any notification or UI surface visible to the reported party.
