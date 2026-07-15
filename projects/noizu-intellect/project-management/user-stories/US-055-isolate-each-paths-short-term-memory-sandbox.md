---
id: US-055
title: "Isolate each path's short-term memory sandbox"
slug: isolate-each-paths-short-term-memory-sandbox
personas: [P-001, P-002]
epic: "Parallel-Path Execution"
priority: must-have
complexity: high
tags: [memory-sandbox, isolation, short-term-memory, path-scoped]
---

# US-055: Isolate Each Path's Short-Term Memory Sandbox

## User Story

**As a** solo staff engineer
**I want to** guarantee that each path's short-term memory (observations, working notes, reflection-emitted patches) is sandboxed to that path only
**So that** losing paths' memories can be discarded cleanly and no path is contaminated by what a sibling path "learned" mid-run

## Acceptance Criteria

- **Given** N paths fork from a shared base checkpoint (US-044)
  **When** each path's agents accumulate new short-term memories, observations, or opinions during their turns
  **Then** those writes land in a memory sandbox scoped to that path's id only, and are never visible to sibling paths' Plan passes or context assembly

- **Given** a path is not picked as the winner (US-054/Picker workflow)
  **When** the run concludes and the pick is finalized
  **Then** that path's short-term memory sandbox is discarded, while its message history and outcome record (US-051) remain retained for audit — discard applies to the working-memory layer only, not the durable transcript

- **Given** the winning path is selected
  **When** the reward signal back-propagates onto decision-factor weights
  **Then** only the winning path's short-term memories are eligible for promotion into an agent's long-term memory (Postgres + vector store), never a losing path's

- **Given** two sibling paths run concurrently and one crashes or is cancelled (US-048) mid-turn
  **When** the crash occurs
  **Then** the failure and any partial memory writes are confined to that path's sandbox and cannot corrupt or leak into a sibling path's sandbox or the shared base checkpoint

## Notes
This isolation guarantee is what makes the "losing paths' memories are discarded" mechanic from the product's core design safe to implement — without hard sandbox boundaries, discard-on-loss would risk silently deleting or corrupting a winning path's state. Mara (P-002) cares about this because it's also what keeps her prompt A/B forks from bleeding into each other's cognition history.
