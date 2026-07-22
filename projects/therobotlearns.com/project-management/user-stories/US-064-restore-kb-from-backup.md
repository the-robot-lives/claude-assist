---
id: US-064
title: "Restore the KB from a Chosen Backup"
slug: restore-kb-from-backup
personas: [P-008, P-006]
epic: "KB Maintenance"
priority: should-have
complexity: medium
tags: [restore, backup, recovery]
---

# US-064: Restore the KB from a Chosen Backup

## User Story

**As a** privacy-first offline consultant recovering from a bad edit or failed migration
**I want to** restore my KB from a specific prior backup
**So that** I can undo damage without losing everything I built since the last good state

## Acceptance Criteria

- **Given** multiple backups exist (git commits and/or archives)
  **When** I run the restore command
  **Then** I'm shown a list of available backups with their timestamps and source (git commit vs. archive) to choose from

- **Given** I select a backup to restore
  **When** I confirm the restore
  **Then** my current KB state is itself backed up first, so the restore action is reversible

- **Given** the restore completes
  **When** I check the KB
  **Then** index.yaml and the flashcard deck index reflect the restored state consistently, with no orphaned references

- **Given** I select an archive backup that is corrupted or incomplete
  **When** restore attempts to use it
  **Then** I get a clear error and my current KB state is left unmodified

## Notes
Builds on the backups produced by [[US-063]] and the automatic pre-migration backups from [[US-062]].
