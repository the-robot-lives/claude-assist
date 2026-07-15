---
id: US-051
title: "Emit a normalized outcome record on path completion"
slug: emit-a-normalized-outcome-record-on-path-completion
personas: [P-001, P-005]
epic: "Parallel-Path Execution"
priority: must-have
complexity: medium
tags: [outcome-record, grading, reviewer, path-completion]
---

# US-051: Emit a Normalized Outcome Record on Path Completion

## User Story

**As a** researcher
**I want to** have every completed path automatically produce a normalized outcome record — regardless of what the path's agents actually did
**So that** the Reviewer can grade paths consistently and I can compare or export results across runs without hand-parsing free-form agent output

## Acceptance Criteria

- **Given** a path's final agent turn signals completion (explicit done signal or reaching its terminal objective)
  **When** the path transitions to "completed"
  **Then** the system emits an outcome record containing: path id, final tag/checkpoint, turn count, total tokens/spend, elapsed wall time, agents involved, and a structured summary of the path's result, all as a single addressable artifact

- **Given** an outcome record is emitted
  **When** it's created
  **Then** it also auto-creates a completion tag on the path thread (consumable by deferred messages, US-050), so completion is both a gradeable record and a checkpoint in one action

- **Given** two paths in the same run complete with very different content shapes (one produces code, another produces a design doc)
  **When** their outcome records are compared
  **Then** both conform to the same schema (same top-level fields), so the Reviewer and any downstream tooling can process them uniformly even though the domain content differs

- **Given** a path is cancelled (US-048) or fails rather than completing normally
  **When** that terminal state is reached
  **Then** an outcome record is still emitted, marked with that terminal status, so failure/cancellation is gradeable data rather than an information gap

## Notes
The outcome record is the contract between path execution and everything downstream: Reviewer grading, Picker selection, reward back-propagation onto decision-factor weights, and Elias's bulk export workflows. Schema stability here matters more than richness — this is the seam the rest of the grading pipeline is built on.
