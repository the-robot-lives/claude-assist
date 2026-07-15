---
id: US-067
title: "Write back only the winning path's memories"
slug: write-back-only-the-winning-paths-memories
personas: [P-001, P-002]
epic: "Memory & Knowledge"
priority: must-have
complexity: high
tags: [memory, winner-takes-all, path-execution]
---

# US-067: Write Back Only the Winning Path's Memories

## User Story

**As a** staff engineer (Devon Reyes) running parallel-path experiments
**I want to** have only the winning path's short-term memories persisted to each agent's long-term memory, with losing paths' memories discarded
**So that** agents don't accumulate contradictory or low-quality memories from approaches that didn't get picked

## Acceptance Criteria

- **Given** a run with N completed paths and a finalized pick
  **When** memory write-back runs
  **Then** every reflection patch (memories, observations, opinions, mind-readings, objectives, reminders) produced along the winning path's sandboxed short-term memory is promoted to the relevant agents' long-term memory store, and the losing paths' sandboxed memories are deleted

- **Given** a rejected run ([[US-061]])
  **When** write-back would normally run
  **Then** no path's memory is promoted — all sandboxed memories for that run are discarded

- **Given** a memory promoted from the winning path
  **When** it lands in long-term memory
  **Then** it retains a reference back to the originating run and path so it can be traced during memory-provenance inspection ([[US-070]])

## Notes
This is the mechanism that makes per-path memory sandboxing ("forking from a shared context checkpoint") safe — nothing pollutes agent memory until a pick is made. Discard must be a real delete or TTL-expire of the sandbox, not just an unreferenced flag, to satisfy the redaction/audit story ([[US-071]]) later.
