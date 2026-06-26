---
id: US-643
title: "Block Evasion via Alt Account Flagging"
slug: block-evasion-via-alt-account-flagging
personas: [P-007]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: high
tags: [safety, blocking, evasion]
---

# US-643: Block Evasion via Alt Account Flagging

## User Story

**As a** channel moderator
**I want to** be able to report a suspected alt account that is evading a community block
**So that** the Trust & Safety team can investigate and take action on coordinated evasion

## Acceptance Criteria

- **Given** I encounter an account behaving identically to a previously blocked user
  **When** I report the account and select "Suspected block evasion"
  **Then** the report is escalated to a high-priority queue distinct from standard reports

- **Given** the evasion report is filed
  **When** I return to my moderation dashboard
  **Then** the report appears with status "Under review — evasion suspected"

## Notes
Moderators can flag on behalf of the channel; individual users can also report via the standard report flow.
