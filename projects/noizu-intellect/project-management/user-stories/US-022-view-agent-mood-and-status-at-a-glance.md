---
id: US-022
title: "View agent mood and status at a glance"
slug: view-agent-mood-and-status-at-a-glance
personas: [P-003, P-001]
epic: "Agents & Cognition"
priority: could-have
complexity: low
tags: [status, mood, roster-visibility]
---

# US-022: View Agent Mood and Status at a Glance

## User Story

**As a** team lead managing a hybrid human+agent team
**I want to** see each agent's current process status (active/idle/suspended) and a derived "mood" indicator in the team roster
**So that** I can quickly tell which agents are working, stuck, or need attention without opening each one individually

## Acceptance Criteria

- **Given** an agent's process is active, idle, or suspended
  **When** I view the team roster
  **Then** each agent shows a status badge reflecting its current process state, refreshed live via the PubSub streaming mechanic

- **Given** an agent's recent Reflect passes indicate repeated negative outcomes (e.g., low grades, failed turns)
  **When** the roster computes its mood indicator
  **Then** the agent shows a degraded-mood indicator distinct from its process status, prompting the lead to investigate

- **Given** I hover or click an agent's status badge
  **When** the detail popover opens
  **Then** it shows the last turn timestamp, current channel activity, and a link into the turn debug view (US-018)

- **Given** an agent has been suspended (US-015)
  **When** viewing the roster
  **Then** its status badge clearly reads "suspended" rather than a stale "idle" state

## Notes
"Mood" is a derived/heuristic indicator (e.g., from recent grades or reflection sentiment), not a stored cognition field — it's a roster-level UX affordance, not a new mechanic. Complements US-015's suspend/wake controls and US-018's turn debugging.
