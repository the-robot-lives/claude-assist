---
id: US-095
title: "Incremental index updates"
slug: incremental-index-updates
personas: [P-003]
epic: "Performance & Scale"
priority: should-have
complexity: medium
tags: [performance, indexing]
---

# US-095: Incremental Index Updates

## User Story

**As an** SRE/DevOps polymath with a huge knowledge base
**I want to** have the KB index update incrementally rather than rebuilding fully
**So that** adding or editing content doesn't trigger a slow full re-index

## Acceptance Criteria

- **Given** a single article or card is added or edited
  **When** the KB index is updated
  **Then** only the affected entries are re-indexed, not the entire index.yaml

- **Given** an incremental update completes
  **When** compared to a full rebuild of the same KB
  **Then** the incremental update is measurably faster

- **Given** the index becomes inconsistent (e.g., after an interrupted update)
  **When** the user triggers a full rebuild
  **Then** that fallback path is still available and produces a correct index

## Notes
Depends on / complements US-093's scale target.
