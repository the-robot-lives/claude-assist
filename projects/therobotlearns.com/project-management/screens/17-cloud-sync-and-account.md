# Cloud Sync & Account

| Field | Value |
|-------|-------|
| **ID** | `cloud-sync-and-account` |
| **Type** | Primary |
| **Category** | Collaboration & Cloud |
| **User Stories** | US-076, US-077, US-081 |

## Description

The (future) therobotlearns.com cloud tier: optional sync of a local KB to a hosted account, and a shared team KB that stays consistent across every member's local install.

## Key Components

- **Diff/Merge Conflict Resolver** — item-by-item conflict resolution (US-081)
- **KB Stat Tile** — sync status (US-076)

## Interactions

- Optionally sync the local KB to a therobotlearns.com cloud account for multi-machine access (US-076).
- Maintain a shared team KB that syncs to every member's local install (US-077).
- Walk through resolving merge conflicts item-by-item when a synced KB has diverged (US-081).

## Navigation

- Accessible from: Settings & Preferences, Import / Export & Sharing.
- Links to: Team Lead Dashboard, Import / Export & Sharing.
