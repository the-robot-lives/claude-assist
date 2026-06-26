---
id: US-676
title: "Repeat Offender Handling"
slug: repeat-offender-handling
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, repeat-offenders]
---

# US-676: Repeat Offender Handling

## User Story

**As a** channel moderator
**I want to** see a user's prior violation history surfaced automatically when I take action
**So that** I can apply an appropriately escalated sanction rather than restarting the ladder from a warning each time

## Acceptance Criteria

- **Given** I am about to issue a sanction to a user
  **When** I open the action dialog
  **Then** the dialog shows a "Prior actions in this channel" summary: number of warnings, timeouts, and bans, with dates, and a recommended next action based on the sanctions ladder

- **Given** a user has received 3 or more sanctions in 30 days
  **When** the next report involving them is reviewed
  **Then** their report card is marked "Repeat offender" and elevated in queue priority

- **Given** a repeat-offender flag is present
  **When** I apply a sanction
  **Then** the system prompts me to consider escalating to platform T&S for potential platform-wide action

## Notes
The sanctions ladder (warn → short timeout → long timeout → channel ban → escalate) should be configurable by channel owners.
