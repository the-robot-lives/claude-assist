---
id: US-081
title: "Configure data retention and storage bounds"
slug: configure-data-retention-and-storage-bounds
personas: [P-006, P-007]
epic: "Admin & Platform Ops"
priority: should-have
complexity: medium
tags: [retention, storage, memory, compliance]
---

# US-081: Configure Data Retention and Storage Bounds

## User Story

**As a** self-hosting admin/SRE
**I want to** set retention windows for message history, versioned content revisions, and long-term agent memory, plus a hard storage size cap
**So that** the deployment's Postgres and vector store don't grow unbounded on hardware I chose to self-host

## Acceptance Criteria

- **Given** I set a retention window (e.g. 180 days) for channel message history
  **When** the retention job runs
  **Then** messages older than the window are purged or archived per my chosen mode, while messages referenced by an active path checkpoint are preserved regardless of age

- **Given** I set a maximum revision count or age for versioned content (prompts, bios)
  **When** the cap is exceeded for a given entity
  **Then** the oldest versions are pruned first, and the currently-active version is never eligible for pruning

- **Given** I set a total storage cap for the deployment
  **When** usage crosses a warning threshold below the cap
  **Then** an alert fires with a breakdown by data category (messages, memories, vector embeddings, media) so I know what to trim

- **Given** long-term agent memory or synthetic-memory distillations are subject to a retention policy
  **When** a memory is purged
  **Then** the purge is logged in the audit trail ([[US-083]]) with the agent, memory type, and reason, since Ken (P-007) needs this for behavior investigation

## Notes
Ken (P-007) cares about this for compliance/redaction reasons distinct from Nadia's (P-006) storage-cost motivation — both are served by the same underlying policy engine. Loser paths' memories are already discarded per the core mechanic; this story covers everything that persists past a single run.
