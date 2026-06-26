---
id: US-666
title: "Moderator Reviews Appeal"
slug: moderator-reviews-appeal
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [appeals, moderation]
---

# US-666: Moderator Reviews Appeal

## User Story

**As a** channel moderator
**I want to** review a pending appeal and see the original content alongside the removal reason
**So that** I can make a fair, informed decision to uphold or overturn the action

## Acceptance Criteria

- **Given** an appeal is in my channel's appeal queue
  **When** I open it
  **Then** I see the original post content (even if removed), the rule cited, the appellant's statement, and the prior mod action history for that user in this channel

- **Given** I decide to overturn the removal
  **When** I click "Restore Content"
  **Then** the post is restored, the sanction is lifted, the appellant is notified, and the reversal is logged in the audit trail

- **Given** I decide to uphold the removal
  **When** I click "Uphold Decision" with a brief reason
  **Then** the appellant is notified of the outcome and told they may escalate to platform T&S

## Notes
Appeal decisions should carry the same audit-log weight as original actions to maintain accountability.
