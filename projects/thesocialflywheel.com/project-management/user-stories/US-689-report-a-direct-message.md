---
id: US-689
title: "Report a Direct Message"
slug: report-a-direct-message
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [reporting, dms, privacy]
---

# US-689: Report a Direct Message

## User Story

**As a** cautious newcomer receiving harassing direct messages
**I want to** report a DM to platform Trust & Safety
**So that** the abuse is investigated without the sender knowing I reported them

## Acceptance Criteria

- **Given** I am in a DM conversation
  **When** I long-press a message and select "Report Message"
  **Then** the report is submitted directly to platform T&S (not the channel mod) with the message content and surrounding context preserved as evidence

- **Given** I submit a DM report
  **When** the report is created
  **Then** the sender receives no notification or indication that I have reported them

- **Given** a DM report is submitted
  **When** I choose to block the sender immediately
  **Then** the block is applied at the same time as the report submission so I do not need to take a separate action

## Notes
DM evidence must be stored securely and accessible only to platform T&S reviewers; channel mods must not have access to private message content.
