---
id: US-630
title: "Report and Block in One Action"
slug: report-and-block-in-one-action
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, reporting, blocking]
---

# US-630: Report and Block in One Action

## User Story

**As a** cautious newcomer
**I want to** report a user for harmful behaviour and block them in a single flow
**So that** I am immediately protected while also flagging the issue to the moderation team

## Acceptance Criteria

- **Given** I open the "Report" flow from a post or profile
  **When** I select a violation category and submit
  **Then** a final step asks "Also block this user?" with Block and Skip buttons

- **Given** I choose Block in the final step
  **When** the report is submitted
  **Then** the report is filed AND a block (at default scope) is applied simultaneously

- **Given** the combined action completes
  **When** I return to my feed
  **Then** the reported user's content is no longer visible

## Notes
Reporting and blocking are recorded as separate events; blocking alone does not constitute a report.
