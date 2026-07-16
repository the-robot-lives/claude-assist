# KB Maintenance Console

| Field | Value |
|-------|-------|
| **ID** | `kb-maintenance-console` |
| **Type** | Primary |
| **Category** | KB Maintenance |
| **User Stories** | US-014, US-056, US-057, US-058, US-059, US-060, US-061, US-065, US-093, US-095 |

## Description

The health-and-hygiene surface for the knowledge base itself: index consistency, schema validation, duplicate detection, pruning, stats, and template migrations. Where the KB stays correct and fast as it scales to thousands of entries.

## Key Components

- **KB Stat Tile** — article counts, deck sizes, growth over time (US-060)
- **Error/Warning Banner** — schema validation failures (US-056)
- **Confirmation Prompt** — migration and prune guards (US-061, US-059)

## Interactions

- The index updates automatically and incrementally whenever an article is added, without a full rebuild (US-014, US-095).
- Validate every YAML/Markdown file against its governing schema on demand (US-056).
- Rebuild `index.yaml` from what's actually on disk when it's drifted (US-057).
- Detect duplicate or overlapping articles and suggest merges (US-058).
- Identify and archive stale articles (US-059).
- View KB stats: article counts, deck sizes, topic coverage, growth over time (US-060).
- Migrate the KB automatically when a new launcher template version ships (US-061).
- Relocate the KB directory to a custom (e.g. encrypted) volume (US-065).
- Index and search stay fast as the KB scales to thousands of entries (US-093).

## Navigation

- Accessible from: `/setup maintenance` or a standalone maintenance command.
- Links to: Backup & Restore, KB Browse & Search.
