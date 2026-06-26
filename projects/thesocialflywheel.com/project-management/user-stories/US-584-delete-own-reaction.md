---
id: US-584
title: "Delete My Own Reaction"
slug: delete-own-reaction
personas: [P-006]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [reactions, delete, engagement]
---

# US-584: Delete My Own Reaction

## User Story

**As a** Quiet Consumer
**I want to** remove a reaction I placed deliberately
**So that** I can correct engagement that no longer reflects my view

## Acceptance Criteria

- **Given** I have reacted to a post
  **When** I tap my active reaction icon and confirm "Remove reaction?" in the popover
  **Then** my reaction is removed and the count decrements instantly

- **Given** the reaction is removed
  **Then** no notification is sent to the post author about the removal

## Notes
This story covers the confirmed-deletion flow with a popover; contrast with US-565 (quick undo with single tap). Both paths result in the same outcome.
