---
id: US-068
title: "Distill a long conversation into synthetic long-term memory"
slug: distill-a-long-conversation-into-synthetic-long-term-memory
personas: [P-002]
epic: "Memory & Knowledge"
priority: should-have
complexity: high
tags: [memory, synthetic-distillation, cognition]
---

# US-068: Distill a Long Conversation Into Synthetic Long-Term Memory

## User Story

**As an** agent designer (Mara Lindqvist) tuning an agent's cognition over time
**I want to** trigger synthetic-memory distillation on a long channel conversation
**So that** the agent retains the important takeaways as compact long-term memory records instead of relying on an ever-growing raw transcript

## Acceptance Criteria

- **Given** a channel conversation that has exceeded a configurable length or age threshold
  **When** distillation runs (on-demand or scheduled)
  **Then** it produces a small set of synthetic memory records summarizing key facts, decisions, and open threads, each tagged with its source conversation range

- **Given** a distilled memory record
  **When** I (as the agent designer) inspect it
  **Then** I can see it is versioned content distinct from the raw reflection-patch memories produced during normal turns, so I can tell distilled summaries apart from directly observed memories

- **Given** a distillation pass over a conversation involving multiple agents
  **When** it completes
  **Then** each agent that was an active participant receives its own distilled memory record reflecting its perspective, rather than one shared record applied uniformly to all participants

## Notes
Distillation is distinct from per-path write-back ([[US-067]]) — it operates on long-running channel history, not path sandboxes. Should be queued via the existing Oban memory queue rather than run inline to avoid blocking the channel.
