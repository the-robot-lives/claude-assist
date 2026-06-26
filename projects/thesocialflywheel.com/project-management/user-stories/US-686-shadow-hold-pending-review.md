---
id: US-686
title: "Shadow Hold Pending Review"
slug: shadow-hold-pending-review
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [moderation, shadow-hold, content-review]
---

# US-686: Shadow Hold Pending Review

## User Story

**As a** channel moderator investigating a borderline post
**I want to** place a post in shadow hold so it is visible only to its author and mods
**So that** the content is not amplified to the community while I gather context, without alerting the poster to the investigation

## Acceptance Criteria

- **Given** I select "Shadow Hold" on a post from the report card
  **When** the hold is applied
  **Then** the post disappears from all member feeds but continues to display normally when the author views their own profile, so they do not know the investigation is underway

- **Given** a post is in shadow hold
  **When** I complete my review and decide to restore it
  **Then** the post reappears in the channel feed with its original timestamp and engagement counts intact

- **Given** a post is in shadow hold
  **When** I decide it violates rules
  **Then** I can convert the shadow hold directly to a removal, at which point the author is notified per the standard removal flow

## Notes
Shadow hold duration should be capped at 72 hours by default; posts not resolved by then auto-escalate to prevent indefinite suppression without notice.
