# Backup / Restore Timeline

| Field | Value |
|-------|-------|
| **ID** | `backup-restore-timeline` |
| **Category** | Tables & Lists |
| **Used In** | 15-Backup & Restore |

## Description

A chronological list of available KB backups — both automatic pre-migration ones and manual/scheduled ones — each restorable independently.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Compact** | Date, trigger (manual/scheduled/pre-migration), and size |
| **Expanded** | Date, trigger, size, and a diff summary against the current KB state |

## Props / Configuration

- `backups` — array of `{timestamp, trigger, sizeBytes, format}`

## Interactions

- Selecting a backup opens the restore Confirmation Prompt; backups can be pruned individually.
