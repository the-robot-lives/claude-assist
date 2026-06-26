---
id: US-579
title: "View My Reaction History on My Profile"
slug: reaction-history-profile
personas: [P-006]
epic: "Reactions & Engagement"
priority: could-have
complexity: low
tags: [reactions, profile, history]
---

# US-579: View My Reaction History on My Profile

## User Story

**As a** Quiet Consumer
**I want to** see a log of the posts I have reacted to
**So that** I can rediscover content I engaged with earlier

## Acceptance Criteria

- **Given** I navigate to My Profile → Activity
  **When** I select the "Reactions" tab
  **Then** I see posts I reacted to in reverse chronological order with the emoji I used

- **Given** my reaction privacy is set to "Only me"
  **Then** this tab is visible only to me and does not render on my public profile view

## Notes
Reaction history is scoped to the last 90 days by default; older entries require a load-more action.
