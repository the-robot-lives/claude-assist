---
id: US-059
title: "Prune or Archive Stale Articles"
slug: prune-stale-articles
personas: [P-004, P-001]
epic: "KB Maintenance"
priority: should-have
complexity: medium
tags: [archive, prune, lifecycle]
---

# US-059: Prune or Archive Stale Articles

## User Story

**As a** staff backend engineer whose KB has accumulated outdated notes
**I want to** identify and archive articles I no longer need
**So that** searches and "what do I know" summaries stay focused on current, relevant knowledge

## Acceptance Criteria

- **Given** articles haven't been read, referenced, or updated in longer than a configurable staleness threshold
  **When** I run the stale-articles report
  **Then** those articles are listed with their last-touched date and reference count

- **Given** I select one or more stale articles to archive
  **When** I confirm the archive action
  **Then** the articles are moved out of the active index into an archive location, not permanently deleted

- **Given** an article was archived by mistake
  **When** I run the restore-from-archive command on it
  **Then** it is returned to the active KB and re-added to index.yaml

- **Given** I want a fully irreversible cleanup
  **When** I explicitly pass a purge flag on an already-archived article
  **Then** I'm given a distinct, harder-to-trigger confirmation before it is permanently deleted

## Notes
Default behavior must be non-destructive (archive, not delete) to avoid accidental knowledge loss.
