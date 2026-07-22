---
id: US-056
title: "Resume an interrupted run after disconnect or restart"
slug: resume-an-interrupted-run-after-disconnect-or-restart
personas: [P-001, P-006]
epic: "Parallel-Path Execution"
priority: must-have
complexity: high
tags: [durability, resume, restart, oban, genserver-recovery]
---

# US-056: Resume an Interrupted Run After Disconnect or Restart

## User Story

**As a** self-hosting admin/SRE
**I want to** have an in-flight parallel-path run survive and correctly resume after a node restart, deploy, or my own client disconnect
**So that** a run in progress isn't lost or left in an inconsistent state just because the process hosting it went away temporarily

## Acceptance Criteria

- **Given** a run has paths mid-turn when the hosting node is restarted (deploy, crash, or planned maintenance)
  **When** the system comes back up
  **Then** each path's GenServer is re-spawned from durable state (last completed turn, memory sandbox contents, turn cap/spend consumed so far), and any turn that was in-flight at the moment of restart is either safely replayed via the Oban job that owned it or marked failed-and-retryable, never silently lost or double-billed

- **Given** my browser/client disconnects while watching a run's live view (US-046)
  **When** I reconnect
  **Then** the live view resyncs to current state immediately (not just new events going forward), showing everything that happened while I was disconnected

- **Given** a run was interrupted mid-turn
  **When** it resumes
  **Then** the resumed turn produces the same outcome-record schema and audit trail as an uninterrupted run — no gap or unmarked discontinuity in the turn history

- **Given** I am the admin monitoring platform health
  **When** I check queue/run health after an incident
  **Then** I can see which runs/paths were affected by the interruption and their recovery status (resumed cleanly, retried, or requiring manual intervention) in one place

## Notes
This durability guarantee is what makes parallel-path execution trustworthy for anything longer than a few minutes — Oban-backed job queues for path execution (per the platform's ops mechanics) are the intended mechanism, so recovery should lean on Oban's own retry/uniqueness semantics rather than a bespoke resume protocol. Directly serves Nadia's (P-006) operational responsibility for self-hosted uptime and incident diagnosis.
