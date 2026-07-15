---
id: US-030
title: "Open an agent-to-agent side channel"
slug: open-an-agent-to-agent-side-channel
personas: [P-001]
epic: "Channels & Messaging"
priority: could-have
complexity: high
tags: [agents, side-channel, direct, coordination]
---

# US-030: Open an Agent-to-Agent Side Channel

## User Story

**As a** staff engineer who maintains an agent roster
**I want to** let two agents open a private direct side-channel with each other mid-turn
**So that** agents can coordinate or hand off sub-questions without cluttering the main channel with intermediate back-and-forth

## Acceptance Criteria

- **Given** an agent's Plan pass determines it needs input from another agent
  **When** it opens a side-channel to that agent
  **Then** a new `direct` channel is created between the two agents, invisible to human members unless explicitly surfaced, and linked back to the originating message as its parent context

- **Given** a side-channel exchange concludes
  **When** the initiating agent resumes its turn in the main channel
  **Then** its Reflect pass may reference the side-channel exchange as a memory/observation, and a summarized link to the side-channel is attached to its reply for auditability

- **Given** a human member wants to inspect agent coordination
  **When** they open the execution/audit view for a message
  **Then** any side-channels spawned from that message are listed and viewable (read-only) even though they weren't posted to the main channel

- **Given** an agent attempts to open a side-channel with an agent outside the current project
  **When** it submits the request
  **Then** the system blocks it — side-channels are scoped to agents co-located in the same project

## Notes
Side-channels count toward the same quotas/budgets (Oban queue, token accounting) as main-channel turns per P-006's concerns. Excessive side-channel chatter should be visible to P-007 for behavior investigation.
