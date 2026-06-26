---
id: US-299
title: "Abuse Report on Match Request"
slug: abuse-report-on-match-request
personas: [P-004]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [safety, reporting, abuse-resistance, inbox]
---

# US-299: Abuse Report on Match Request

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** report an incoming interest as abusive or harassing
**So that** I can flag bad actors from my inbox without having to accept or expose myself to further contact

## Acceptance Criteria

- **Given** I have an incoming interest in my inbox
  **When** I open the interest card's overflow menu
  **Then** I see "Report & Block" alongside "Decline"

- **Given** I submit a "Report & Block" action with a selected reason
  **When** the report is submitted
  **Then** the interest is removed from my inbox, the sender is added to my block list, and the report is queued for moderator review

- **Given** I submit an abuse report
  **When** the action completes
  **Then** I receive confirmation that the report was received and I will not see that user again
