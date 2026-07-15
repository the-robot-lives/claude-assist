---
id: US-015
title: "Wake and suspend an agent process"
slug: wake-and-suspend-an-agent-process
personas: [P-001, P-003]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [agent-lifecycle, genserver, process-control]
---

# US-015: Wake and Suspend an Agent Process

## User Story

**As a** solo staff engineer / team lead
**I want to** manually wake a suspended agent or suspend an active one within a project
**So that** I control compute/spend and can pause an agent that is behaving unexpectedly without deleting it

## Acceptance Criteria

- **Given** an agent's process for a project is suspended
  **When** I trigger "wake"
  **Then** its GenServer starts, it resumes consuming its channel inbox, and its status flips to active/idle within seconds

- **Given** an agent's process is active and mid-turn
  **When** I trigger "suspend"
  **Then** the current Plan/Reply/Reflect pass in progress completes (or is checkpointed) before the process stops, and no partial reflection patch is left corrupting cognition tables

- **Given** an agent is suspended
  **When** new messages arrive in its channel with confidence ≥ its routing threshold
  **Then** the messages queue durably in the per-channel inbox and are processed once the agent is next woken, rather than being dropped

- **Given** I suspend an agent to control spend
  **When** I view the agent's process status
  **Then** it is visibly distinguished from "archived" (US-024) — suspend is reversible and preserves scheduled objectives/reminders

## Notes
Distinct from archive/delete (US-024): suspend is a lightweight, frequent, reversible operation; archive is a lifecycle-ending one. Relevant to P-006 admin spend controls as a secondary concern even though not primary persona here.
