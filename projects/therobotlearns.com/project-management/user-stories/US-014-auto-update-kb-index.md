---
id: US-014
title: "Auto-Update the KB Index"
slug: auto-update-kb-index
personas: [P-001, P-006]
epic: "Knowledge Base"
priority: must-have
complexity: medium
tags: [index, automation, schema]
---

# US-014: Auto-Update the KB Index

## User Story

**As a** KB maintainer
**I want to** have the KB index.yaml update automatically when an article is added
**So that** the index never drifts out of sync with the actual article files

## Acceptance Criteria

- **Given** a new article is saved
  **When** the write completes
  **Then** `index.yaml` is updated to include the new article's metadata (path, title, tags)

- **Given** an article is deleted or moved
  **When** the change is detected
  **Then** `index.yaml` is updated to remove or correct the stale entry

- **Given** `index.yaml` becomes out of sync (e.g., from manual file edits)
  **When** I run an index-repair/rebuild command
  **Then** `index.yaml` is regenerated from the actual article files

## Notes
The index schema is one of the nine governing YAML schemas; keeping it authoritative-but-derived (never hand-edited as source of truth) avoids drift.
