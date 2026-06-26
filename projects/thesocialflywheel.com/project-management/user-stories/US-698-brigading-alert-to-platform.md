---
id: US-698
title: "Brigading Alert to Platform"
slug: brigading-alert-to-platform
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [brigading, escalation, platform-trust-safety]
---

# US-698: Brigading Alert to Platform

## User Story

**As a** platform Trust & Safety reviewer
**I want to** receive an automated alert when the brigading-detection heuristic fires for a channel
**So that** I can assess whether the coordinating accounts should be suspended platform-wide

## Acceptance Criteria

- **Given** the brigading detection system identifies a coordinated reporting cluster targeting a channel
  **When** the confidence score crosses the platform threshold
  **Then** an alert is auto-created in the T&S priority queue containing: the targeted channel, the cluster of suspected brigading accounts, the originating external posts or communities (if detectable), and a timeline of report activity

- **Given** I review the brigading alert
  **When** I determine the activity is coordinated abuse
  **Then** I can suspend all accounts in the cluster in one bulk action and notify the targeted channel's owner of the investigation outcome

- **Given** I determine the alert is a false positive
  **When** I dismiss it
  **Then** the detection parameters for that specific cluster pattern are flagged for engineering review rather than silently discarded

## Notes
Brigading alerts should not be visible to channel mods to prevent vigilante counter-actions before T&S has reviewed the situation.
