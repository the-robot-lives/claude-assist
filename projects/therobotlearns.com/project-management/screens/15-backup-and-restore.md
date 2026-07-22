# Backup & Restore

| Field | Value |
|-------|-------|
| **ID** | `backup-and-restore` |
| **Type** | Primary |
| **Category** | KB Maintenance |
| **User Stories** | US-062, US-063, US-064 |

## Description

Point-in-time protection for the KB: automatic pre-migration backups, on-demand/scheduled backups, and restore from a chosen snapshot.

## Key Components

- **Backup / Restore Timeline** — chronological list of available backups (US-064)
- **Progress Bar / Milestone Tracker** — backup/restore in progress (US-063)
- **Confirmation Prompt** — restore-overwrite guard (US-064)

## Interactions

- A full backup runs automatically before any schema-version migration (US-062).
- Back up the KB on demand or on a schedule, as a git commit or an archive (US-063).
- Restore from a specific prior backup after a bad edit or failed migration (US-064).

## Navigation

- Accessible from: KB Maintenance Console, or the standalone `/backup` command.
- Links to: KB Maintenance Console.
