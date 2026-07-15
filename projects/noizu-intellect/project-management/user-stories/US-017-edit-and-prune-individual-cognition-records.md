---
id: US-017
title: "Edit and prune individual cognition records"
slug: edit-and-prune-individual-cognition-records
personas: [P-002, P-007]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [cognition, memory, redaction]
---

# US-017: Edit and Prune Individual Cognition Records

## User Story

**As a** agent designer/prompt engineer
**I want to** edit the text of a single memory/observation/opinion/mind-reading or delete it outright
**So that** I can correct a stale or wrong belief the agent formed, or remove sensitive content, without waiting for it to naturally decay

## Acceptance Criteria

- **Given** I locate an incorrect opinion in the cognition inspector
  **When** I edit its text and save
  **Then** the record updates in place and is flagged as manually edited, distinct from records produced by an automated Reflect pass

- **Given** a memory record contains sensitive or incorrectly captured information
  **When** I delete it
  **Then** it is removed from the agent's active memory store and excluded from future retrieval/vector search, with a tombstone entry retained for audit purposes

- **Given** a compliance reviewer needs to redact a memory referencing PII
  **When** they perform the redaction
  **Then** the redaction is logged with reviewer identity and timestamp, satisfying an audit trail requirement even though the memory content itself is gone

- **Given** I attempt to bulk-prune all memories older than a date for an agent
  **When** I confirm the bulk action
  **Then** the system requires an explicit confirmation step distinguishing it from a single-record delete, since bulk pruning is destructive and irreversible

## Notes
This is the redaction mechanism P-007 needs for compliance/moderation. Distinguish "edit/delete a record" (this story) from "the Reflect pass automatically prunes/decays memory" (an automated mechanic, not a user action) — this story is specifically the manual override surface.
