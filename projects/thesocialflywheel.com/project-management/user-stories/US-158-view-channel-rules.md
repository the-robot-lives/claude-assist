---
id: US-158
title: "View Channel Rules"
slug: view-channel-rules
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, rules, safety]
---

# US-158: View Channel Rules

## User Story

**As a** Quiet Consumer
**I want to** read the channel rules at any time
**So that** I understand what content and behavior is acceptable before I post

## Acceptance Criteria

- **Given** I am a member of a channel that has published rules
  **When** I open the channel menu and tap "Rules"
  **Then** I see a numbered list of rules with the date they were last updated

- **Given** the channel has no rules set by the moderator
  **When** I navigate to the Rules section
  **Then** I see a placeholder indicating no custom rules have been published, with a note that platform-wide community guidelines still apply

## Notes
Rules should always be accessible from both the channel info page (pre-join) and the in-channel menu (post-join).
