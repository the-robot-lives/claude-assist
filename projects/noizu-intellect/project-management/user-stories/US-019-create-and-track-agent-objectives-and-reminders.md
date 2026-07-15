---
id: US-019
title: "Create and track agent objectives and reminders"
slug: create-and-track-agent-objectives-and-reminders
personas: [P-003, P-002]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [objectives, reminders, cognition]
---

# US-019: Create and Track Agent Objectives and Reminders

## User Story

**As a** team lead delegating work to a hybrid human+agent team
**I want to** create an objective or reminder for a specific agent and track it to completion
**So that** the agent carries follow-up work across turns instead of losing track after a single reply

## Acceptance Criteria

- **Given** I assign an agent an objective ("follow up with Finance by Friday")
  **When** the objective is saved
  **Then** it appears in the agent's objectives cognition table and is surfaced to the agent's Plan pass on subsequent turns until marked complete

- **Given** an agent's Reflect pass determines an objective was satisfied during a turn
  **When** the reflection patch is applied
  **Then** the objective's status automatically updates to complete and the change is visible in the turn's Reflect section (see US-018)

- **Given** I view an agent's open objectives and reminders list
  **When** I filter by status (open, complete, overdue)
  **Then** overdue items (past their target date and still open) are visually flagged

- **Given** I manually mark an objective complete before the agent's Reflect pass would have
  **When** I confirm the manual completion
  **Then** the objective is closed and future Plan passes stop surfacing it, avoiding duplicate follow-up work

## Notes
Objectives/reminders are part of the cognition tables the Reflect pass patches (see product mechanics). This story covers manual creation/tracking by a human; automated updates from Reflect are the underlying mechanic this UI surfaces.
