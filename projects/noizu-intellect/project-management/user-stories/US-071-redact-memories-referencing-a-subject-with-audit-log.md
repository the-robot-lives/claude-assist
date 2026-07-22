---
id: US-071
title: "Redact memories referencing a subject with audit log"
slug: redact-memories-referencing-a-subject-with-audit-log
personas: [P-007]
epic: "Memory & Knowledge"
priority: must-have
complexity: high
tags: [memory, redaction, compliance, audit-log]
---

# US-071: Redact Memories Referencing a Subject With Audit Log

## User Story

**As a** compliance/support investigator (Ken Watanabe)
**I want to** purge or redact every memory record across all agents that references a given subject (person, project, or term)
**So that** I can respond to takedown, privacy, or legal requests without leaving stray references scattered across agent memory stores

## Acceptance Criteria

- **Given** a subject identifier or search query naming what must be redacted
  **When** I run a redaction request
  **Then** the system finds every matching memory record (via semantic and exact search) across all agents in scope, presents them for confirmation, and on approval removes or tombstones each one

- **Given** an approved redaction
  **When** it completes
  **Then** an immutable audit log entry is created recording who requested it, what was matched, what action was taken (delete vs. tombstone), and when — independent of the memory store itself

- **Given** a memory record that was referenced in a provenance record ([[US-070]]) for a past reply
  **When** it is redacted
  **Then** the provenance record retains a "redacted" marker instead of silently breaking or disappearing, preserving the audit trail of that historical reply

## Notes
Redaction must cascade to the vector store as well as the relational memory tables — a tombstoned Postgres row with a lingering Weaviate/pgvector embedding is not a real redaction. Scope must respect cross-project isolation ([[US-073]]) so a redaction request against one project cannot touch another's data.
