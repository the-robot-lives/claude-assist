---
id: US-656
title: "Claim and Triage Report"
slug: claim-and-triage-report
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, triage]
---

# US-656: Claim and Triage Report

## User Story

**As a** channel moderator
**I want to** claim a report and mark it "in review"
**So that** other mods do not duplicate my work while I investigate

## Acceptance Criteria

- **Given** a report is in "new" status in the queue
  **When** I click "Claim"
  **Then** the report status changes to "in review", my display name appears as the assigned mod, and the claim is logged with a timestamp in the audit trail

- **Given** a report is already claimed by another mod
  **When** I view that report card
  **Then** I see the assigned mod's name and cannot claim it unless I use the "Override Claim" action (which requires senior-mod or owner role)

## Notes
Claim override should be audited to prevent power abuse within mod teams.
