---
id: US-096
title: "Recover a run after server restart with no lost or duplicated turns"
slug: recover-a-run-after-server-restart-with-no-lost-or-duplicated-turns
personas: [P-006, P-001]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: must-have
complexity: high
tags: [resilience, genserver, oban, restart-recovery, idempotency]
---

# US-096: Recover a Run After Server Restart With No Lost or Duplicated Turns

## User Story

**As a** self-hosting admin/SRE (Nadia Volkov)
**I want to** have in-progress parallel-path runs resume correctly after a node restart or deploy, with every agent's GenServer state and Oban-queued work restored
**So that** a routine restart never loses a turn already committed or replays a turn twice

## Acceptance Criteria

- **Given** a run with multiple paths mid-execution when the node restarts
  **When** the system comes back up
  **Then** every per-agent-per-project GenServer is respawned from durable state (DB-backed inbox, last committed turn, tag/checkout position) with no manual intervention required

- **Given** a turn that had completed its Plan and Reply passes but not yet its Reflect pass at the moment of restart
  **When** recovery runs
  **Then** the Reflect pass resumes from that exact point — it is not silently skipped and the Plan/Reply output is not regenerated or duplicated

- **Given** an Oban job (ingestion, path-execution, or memory job) that was executing at restart time
  **When** the queue recovers
  **Then** the job either completes idempotently on retry or is detected as already-applied and skipped, so no duplicate messages or duplicate memory writes appear

- **Given** a restart occurring mid-run
  **When** a human later inspects the run's turn history
  **Then** the record is indistinguishable from an uninterrupted run except for an internal marker noting the recovery event, visible only in admin/debug views

## Notes
Depends on turn state being durably persisted at each pass boundary, not only at turn completion, since Plan/Reply/Reflect can be interrupted individually. Complements [[US-095]] — that story covers provider-level failures, this covers infrastructure-level failures.
