---
id: US-653
title: "Report a Channel"
slug: report-a-channel
personas: [P-001]
epic: "Moderation & Reporting"
priority: should-have
complexity: low
tags: [reporting, channel-safety]
---

# US-653: Report a Channel

## User Story

**As a** bridge-builder who participates across many communities
**I want to** report an entire channel for systemic harassment or policy violations
**So that** platform Trust & Safety can investigate and take channel-level action

## Acceptance Criteria

- **Given** I am viewing a channel's landing page or member directory
  **When** I select "Report Channel" and provide a reason and optional description
  **Then** the report is routed directly to platform T&S, not the channel's own moderators

- **Given** a channel report has been submitted
  **When** platform T&S reviews it
  **Then** they can suspend, restrict, or remove the channel and all affected users are notified per platform policy

## Notes
Channel reports must bypass the channel mod queue to avoid the mod being the subject of their own investigation.
