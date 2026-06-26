---
id: US-667
title: "Platform Reviews Escalated Appeal"
slug: platform-reviews-escalated-appeal
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: high
tags: [appeals, platform-trust-safety, escalation]
---

# US-667: Platform Reviews Escalated Appeal

## User Story

**As a** platform Trust & Safety reviewer
**I want to** review appeals that were denied at the channel-mod level
**So that** users have a meaningful second-tier recourse and systemic mod errors are caught

## Acceptance Criteria

- **Given** a channel mod has upheld a removal and the user escalates
  **When** the escalation is submitted
  **Then** a case is created in the platform T&S appeal queue containing the full history: original content, original report, mod action, mod appeal decision, and user's escalation statement

- **Given** I am a platform reviewer with T&S role
  **When** I overturn the channel mod's decision
  **Then** I can restore the content, reverse the sanction, and optionally flag the mod's original action for coaching — all changes are logged and the user is notified

- **Given** platform T&S upholds the denial
  **When** the decision is made
  **Then** the user is notified that the platform decision is final and no further appeals for this action are accepted

## Notes
Platform reviewers must have authority to override channel mods; this override should be visible in the channel audit log marked as "Platform T&S Override".
