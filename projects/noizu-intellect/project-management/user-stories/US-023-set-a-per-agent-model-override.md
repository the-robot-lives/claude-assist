---
id: US-023
title: "Set a per-agent model override"
slug: set-a-per-agent-model-override
personas: [P-002, P-001]
epic: "Agents & Cognition"
priority: should-have
complexity: low
tags: [model-management, provider, override]
---

# US-023: Set a Per-Agent Model Override

## User Story

**As a** agent designer/prompt engineer
**I want to** override the LLM model an individual agent uses, independent of the project's default branch selection policy
**So that** I can pin a specific agent to a model I know suits its persona, even when other agents in the project use `fastest` or `cheapest` dynamic selection

## Acceptance Criteria

- **Given** a project's default branch model policy is `cheapest`
  **When** I set an explicit model override on one agent
  **Then** that agent's turns always use the overridden model regardless of the project default, while other agents continue following the project policy

- **Given** an agent has a model override set
  **When** the overridden provider/model becomes unavailable
  **Then** the fallback chain for that agent still applies (per model-management fallback mechanics), rather than silently reverting to the project default

- **Given** I clear an agent's model override
  **When** the change is saved
  **Then** the agent reverts to inheriting the project's default branch model selection policy on its next turn

- **Given** I set a model override
  **When** I view the agent's profile
  **Then** the override is visibly distinguished from the inherited default so it's clear at a glance the agent is pinned

## Notes
Sits alongside the project-level `fastest`/`cheapest`/constraint-based dynamic selection mechanic — this is the per-agent exception path. Relevant for P-001 wanting a specific high-capability model on a lead agent while cost-optimizing the rest of the roster.
