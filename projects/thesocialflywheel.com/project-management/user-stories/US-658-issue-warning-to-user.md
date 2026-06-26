---
id: US-658
title: "Issue Warning to User"
slug: issue-warning-to-user
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, mod-actions]
---

# US-658: Issue Warning to User

## User Story

**As a** channel moderator
**I want to** send a formal warning to a channel member with a stated reason
**So that** the user understands they are approaching a sanction and the warning is on record

## Acceptance Criteria

- **Given** I am reviewing a report or viewing a member's profile in my channel
  **When** I select "Issue Warning" and choose or type a reason
  **Then** the user receives a system message detailing the rule violated and is told this warning is logged

- **Given** a warning is issued
  **When** it is recorded
  **Then** it appears in the user's channel-scoped violation history and in the mod audit log with my display name and timestamp

## Notes
Warnings alone do not restrict posting; they serve as the first step in a graduated-sanction ladder.
