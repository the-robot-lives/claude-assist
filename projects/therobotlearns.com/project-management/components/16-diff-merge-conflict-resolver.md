# Diff / Merge Conflict Resolver

| Field | Value |
|-------|-------|
| **ID** | `diff-merge-conflict-resolver` |
| **Category** | Domain-Specific |
| **Used In** | 16-Import / Export & Sharing, 17-Cloud Sync & Account |

## Description

Walks the user through a divergence between two copies of KB content (a shared/synced KB, or an imported bundle) item by item, so nothing is silently overwritten.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Compact** | Conflict count plus a "resolve" action |
| **Expanded** | Side-by-side per-item diff with keep-mine / keep-theirs / merge-both choices |

## Props / Configuration

- `conflicts` — array of `{item, mineVersion, theirVersion}`
- `resolution` — per-item keep-mine \| keep-theirs \| merge

## Interactions

- Item-by-item stepping with a running "resolved N of M" counter; nothing commits until all conflicts are resolved or explicitly deferred.
