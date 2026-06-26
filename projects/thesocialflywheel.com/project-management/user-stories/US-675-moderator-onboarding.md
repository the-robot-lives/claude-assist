---
id: US-675
title: "Moderator Onboarding"
slug: moderator-onboarding
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [moderation, onboarding]
---

# US-675: Moderator Onboarding

## User Story

**As a** user newly assigned a moderator role in a channel
**I want to** complete a guided onboarding checklist before accessing the live report queue
**So that** I understand my responsibilities, available tools, and the opposing-views moderation policy before making consequential decisions

## Acceptance Criteria

- **Given** I am assigned a mod role for the first time in a channel
  **When** I next open that channel's mod panel
  **Then** I see a mandatory onboarding flow covering: channel rules setup, action types and sanctions ladder, escalation policy, and the opposing-views dissent-vs-abuse guidelines — with a progress indicator

- **Given** I complete the onboarding checklist
  **When** I confirm each section
  **Then** my completion is recorded in the audit log and the main report queue becomes accessible

- **Given** platform policy is updated significantly
  **When** I next log in as a mod
  **Then** I am shown a "Policy updated" prompt highlighting the changes before accessing the queue, with an option to review the full onboarding again

## Notes
Onboarding completion should be a prerequisite for the "ban" action but not for lower-stakes actions (warn) so new mods can act on urgent cases after completing only the first two sections.
