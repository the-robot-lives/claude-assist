---
id: US-070
title: "Inspect which memories informed a given reply"
slug: inspect-which-memories-informed-a-given-reply
personas: [P-002, P-007]
epic: "Memory & Knowledge"
priority: should-have
complexity: medium
tags: [memory, provenance, audit]
---

# US-070: Inspect Which Memories Informed a Given Reply

## User Story

**As an** agent designer (Mara Lindqvist) or compliance investigator (Ken Watanabe)
**I want to** view the specific set of memory records that were retrieved and fed into an agent's context for a given reply
**So that** I can explain, debug, or audit why the agent said what it said

## Acceptance Criteria

- **Given** a specific agent reply in a channel
  **When** I open its provenance view
  **Then** I see the ordered list of memory records (with content, source, and retrieval score) that were included in that turn's Plan pass context

- **Given** a reply produced during a parallel-path run
  **When** I inspect its provenance
  **Then** the view also shows which path and checkpoint tag the memory context was forked from, distinguishing sandboxed short-term memory from promoted long-term memory

- **Given** a compliance investigation (Ken Watanabe) into a specific past incident
  **When** they inspect provenance for a flagged reply
  **Then** the record is immutable and timestamped, suitable as an audit artifact even if the underlying memory has since been redacted ([[US-071]])

## Notes
Provenance records should reference memory IDs rather than embedding full memory content inline, so that a later redaction can still leave an auditable "a memory existed here, now redacted" trail per [[US-071]].
