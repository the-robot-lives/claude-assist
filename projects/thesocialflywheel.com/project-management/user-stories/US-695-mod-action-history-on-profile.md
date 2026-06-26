---
id: US-695
title: "Mod Action History on Profile"
slug: mod-action-history-on-profile
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, audit, user-profile]
---

# US-695: Mod Action History on Profile

## User Story

**As a** channel moderator reviewing a report
**I want to** see the reported user's channel-scoped moderation history without leaving the report card
**So that** I can make a proportionate decision in context without switching screens

## Acceptance Criteria

- **Given** I am viewing a report card for a post by a specific user
  **When** I click the user's name or avatar within the report card
  **Then** a side panel opens showing their channel-scoped history: warnings, timeouts, bans, prior reports (count only, no details), and any active sanctions

- **Given** the user has no prior history in this channel
  **When** the panel opens
  **Then** it clearly states "No prior actions in this channel" to avoid me assuming a blank panel means data is missing

- **Given** the user has history in the channel
  **When** I see entries with dates older than 6 months
  **Then** they are visually de-emphasised (greyed out) to help me weight recent behaviour more heavily

## Notes
History shown here is channel-scoped only; cross-channel history is visible only to platform T&S reviewers.
