---
id: US-062
title: "Automatic Pre-Migration Backup on Schema Changes"
slug: automatic-pre-migration-backup
personas: [P-008, P-006]
epic: "KB Maintenance"
priority: must-have
complexity: medium
tags: [migration, backup, safety]
---

# US-062: Automatic Pre-Migration Backup on Schema Changes

## User Story

**As a** privacy-first offline consultant who can't risk losing local data
**I want to** have my entire KB backed up automatically before any schema-version migration runs
**So that** a failed or unwanted migration can never leave me without a way back

## Acceptance Criteria

- **Given** a schema-version migration is about to run against my KB
  **When** the migration is triggered
  **Then** a full backup is created and verified before a single file is modified

- **Given** the backup step fails for any reason (disk space, permissions, etc.)
  **When** that happens
  **Then** the migration aborts entirely and no schema files are touched

- **Given** a migration completes
  **When** I check the backup
  **Then** it's timestamped, labeled with the pre-migration schema version, and easy to distinguish from manual backups

- **Given** I want to skip the automatic backup for a trivial migration
  **When** I pass an explicit override flag
  **Then** I get a strong warning before the migration proceeds without one

## Notes
Feeds directly into [[US-064]] for restoring if a migration goes wrong. Reuses the backup mechanism from [[US-063]].
