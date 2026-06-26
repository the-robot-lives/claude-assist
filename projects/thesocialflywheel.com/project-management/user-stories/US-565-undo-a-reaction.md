---
id: US-565
title: "Undo a Reaction"
slug: undo-a-reaction
personas: [P-006]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [reactions, undo, engagement]
---

# US-565: Undo a Reaction

## User Story

**As a** Quiet Consumer
**I want to** undo a reaction I placed by mistake
**So that** my engagement accurately reflects my intent

## Acceptance Criteria

- **Given** I have reacted to a post
  **When** I tap my active reaction icon
  **Then** the reaction is removed and the count decrements immediately

- **Given** I undo a reaction
  **Then** no notification is sent to the post author about the removal

## Notes
Undo is available immediately with no time-window restriction. Tapping the same emoji again re-adds the reaction.
