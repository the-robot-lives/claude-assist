---
id: US-711
title: "Notify User of Moderation Appeal Outcome"
slug: appeal-outcome-notification
personas: [P-010]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [moderation, appeals, notifications, trust]
---

# US-711: Notify User of Moderation Appeal Outcome

## User Story

**As a** Skeptical Switcher
**I want to** receive a clear notification when my moderation appeal is resolved
**So that** I know the platform's decision and can take appropriate next steps

## Acceptance Criteria

- **Given** I filed an appeal against a moderation action on my content
  **When** the appeal is resolved by a senior moderator
  **Then** I receive a high-priority in-app notification and email reading "Your appeal on [content type] has been [upheld / denied]"

- **Given** the appeal outcome notification is delivered
  **When** I open it
  **Then** I see the original violation cited, the appeal decision, a brief explanation, and a link to community guidelines

## Notes
Appeal outcomes are always delivered via both in-app and email channels regardless of the user's general email notification preferences.
