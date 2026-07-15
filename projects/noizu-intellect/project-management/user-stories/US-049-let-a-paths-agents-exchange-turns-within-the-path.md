---
id: US-049
title: "Let a path's agents exchange turns within the path"
slug: let-a-paths-agents-exchange-turns-within-the-path
personas: [P-001]
epic: "Parallel-Path Execution"
priority: must-have
complexity: high
tags: [intra-path, agent-to-agent, turn-loop, audience-confidence]
---

# US-049: Let a Path's Agents Exchange Turns Within the Path

## User Story

**As a** solo staff engineer
**I want to** have a path assigned multiple agents that address each other and hand off turns within that single path
**So that** a path can carry out a multi-role approach (e.g. implementer + reviewer) instead of being limited to one agent monologuing to completion

## Acceptance Criteria

- **Given** a path has two or more agents assigned
  **When** agent A completes its Reply pass and its message addresses agent B (`@b-slug`, confidence 100)
  **Then** agent B's turn is scheduled next within the same path thread, consuming the same shared memory sandbox (US-055) and turn-numbered history

- **Given** an agent within a path addresses `@everyone` or leaves the audience ambiguous
  **When** the message is routed
  **Then** the same audience-confidence threshold rules used elsewhere in the product apply (≥50 confidence triggers action) — no special-cased intra-path routing logic

- **Given** two agents in a path keep re-addressing each other with no forward progress
  **When** the exchange exceeds the path's configured max-turn or max-agent-hop limit
  **Then** the path auto-pauses and flags a possible loop for human review, rather than consuming the entire turn/spend cap silently

- **Given** an intra-path agent-to-agent exchange occurs
  **When** I view the path afterward
  **Then** each turn shows which agent acted and which agent(s) it addressed, so the hand-off sequence is reconstructable from the turn history alone

## Notes
This reuses the platform's existing audience-confidence routing rather than inventing path-scoped messaging semantics — intra-path agent chatter is just channel messaging scoped to a path thread. The loop-detection guard is what keeps this story from silently colliding with the per-path turn cap in US-041.
