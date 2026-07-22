---
id: US-076
title: "Define a model tier with routing and fallback"
slug: define-a-model-tier-with-routing-and-fallback
personas: [P-006]
epic: "Admin & Platform Ops"
priority: must-have
complexity: high
tags: [model-tiers, routing, fallback, providers]
---

# US-076: Define a Model Tier With Routing and Fallback

## User Story

**As a** self-hosting admin/SRE
**I want to** define named model tiers (e.g. `fastest`, `cheapest`, `frontier`) that map to a ranked list of provider/model pairs with automatic fallback
**So that** agent branches can request a tier by constraint and keep running even when the primary provider fails

## Acceptance Criteria

- **Given** I am creating a tier named `cheapest`
  **When** I add a ranked list of provider/model pairs
  **Then** the tier is saved and becomes selectable wherever agents choose a model constraint instead of a literal model id

- **Given** a tier has a primary provider and one or more fallback providers
  **When** the primary provider returns a hard failure (timeout, 5xx, auth error) during an agent turn
  **Then** the request is retried against the next ranked provider and the fallback event is logged with the tier, path, and failing provider

- **Given** all providers in a tier are exhausted
  **When** a turn requests that tier
  **Then** the turn fails with a structured error the Planner/Reviewer can surface, rather than hanging or silently substituting an unrelated model

- **Given** a tier is edited to reorder or remove providers
  **When** the change is saved
  **Then** in-flight turns keep their already-resolved provider and only new turns pick up the new ranking

## Notes
Maps directly to "multiple LLM providers, per-branch dynamic model selection (`fastest`, `cheapest`, constraints), fallbacks" in CONSOLIDATION.md. Depends on [[US-075]] existing providers.
