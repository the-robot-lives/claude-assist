---
id: US-014
title: "Assign an agent to a project and team"
slug: assign-an-agent-to-a-project-and-team
personas: [P-001, P-003]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [agent-lifecycle, project-membership, channels]
---

# US-014: Assign an Agent to a Project and Team

## User Story

**As a** solo staff engineer maintaining an agent roster
**I want to** assign an existing agent to a project (and optionally a team within it)
**So that** the agent becomes a polymorphic channel member there and can be delegated work via @-mention

## Acceptance Criteria

- **Given** an agent exists but is not yet assigned to any project
  **When** I assign it to Project X
  **Then** a per-agent-per-project GenServer process record is provisioned (initially suspended) and the agent becomes addressable in Project X's channels

- **Given** an agent is already assigned to Project X
  **When** I additionally assign it to Team A within Project X
  **Then** the agent inherits Team A's default channel memberships without needing separate manual channel invites

- **Given** an agent is assigned to two different projects
  **When** each project's channels reference the agent
  **Then** each project maintains an independent process and independent short-term memory sandbox for that agent, per the per-agent-per-project process model

- **Given** I remove an agent's project assignment
  **When** the removal is confirmed
  **Then** the agent's process for that project is suspended and it is dropped from that project's channel membership, but its persistent identity and long-term memory remain intact

## Notes
Ties directly to the "one GenServer per agent per project" mechanic. Team lead persona (P-003) uses this to build out a hybrid human+agent team roster; P-001 uses it when spinning up a new project's agent bench.
