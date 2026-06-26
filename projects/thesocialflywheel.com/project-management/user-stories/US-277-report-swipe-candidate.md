---
id: US-277
title: "Report Swipe Candidate"
slug: report-swipe-candidate
personas: [P-004]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [safety, reporting, abuse-resistance]
---

# US-277: Report Swipe Candidate

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** report a swipe card that contains harmful or inappropriate content
**So that** I can flag it for moderator review without having to first connect with the person

## Acceptance Criteria

- **Given** I am viewing a swipe card
  **When** I tap the overflow menu on the card
  **Then** I see a "Report" option alongside "Block" and "Skip"

- **Given** I submit a report with a selected reason
  **When** the report is submitted
  **Then** the card is immediately removed from my queue and I see a confirmation that the report was received
