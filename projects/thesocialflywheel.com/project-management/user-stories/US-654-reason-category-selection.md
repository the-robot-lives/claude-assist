---
id: US-654
title: "Reason Category Selection"
slug: reason-category-selection
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [reporting, ux]
---

# US-654: Reason Category Selection

## User Story

**As a** cautious newcomer filing a report
**I want to** select a structured reason category for my report
**So that** the report is routed to the correct moderation queue and actioned consistently

## Acceptance Criteria

- **Given** I open the report flow for a post
  **When** the reason sheet is presented
  **Then** I see exactly these categories: Spam, Hate Speech, Harassment, Misinformation, CSAM, Self-harm, Other — with plain-language descriptions for each

- **Given** I select a reason category
  **When** I submit the report
  **Then** the category is stored on the report record and used to route the case (CSAM and Self-harm auto-escalate to platform T&S)

## Notes
CSAM and credible self-harm reports must trigger immediate escalation and must not sit in the standard channel-mod queue.
