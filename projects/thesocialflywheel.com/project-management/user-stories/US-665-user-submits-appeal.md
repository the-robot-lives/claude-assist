---
id: US-665
title: "User Submits Appeal"
slug: user-submits-appeal
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [appeals, user-rights]
---

# US-665: User Submits Appeal

## User Story

**As a** cautious newcomer whose post was removed or account sanctioned
**I want to** submit an appeal with a brief statement
**So that** the decision can be reviewed and potentially reversed if it was made in error

## Acceptance Criteria

- **Given** my post has been removed or I have received a timeout or ban
  **When** I view the action notification
  **Then** I see an "Appeal this decision" link that opens an appeal form with the original content, stated reason, and a free-text field (max 500 characters)

- **Given** I submit an appeal
  **When** the appeal is received
  **Then** I get a confirmation notification and the appeal is queued for the channel mod (channel actions) or platform T&S (global actions) with a target response time displayed

- **Given** my appeal is pending
  **When** I check my notification centre
  **Then** I can see the appeal status (submitted / under review / decided)

## Notes
Users should be limited to one active appeal per action to prevent queue flooding.
