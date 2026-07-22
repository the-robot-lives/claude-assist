# Entry Versions API

Snapshot-on-write (ADR-007). Tables: changelogs 036–038.

## `GET /api/v1/universes/:universe_id/entries/:id/versions`

**200:** `{ "versions": [ { "id", "version", "reason", "created_by", "inserted_at" } ] }`

## `GET /api/v1/universes/:universe_id/entries/:id/versions/:version`

**200:** `{ "version": { …, "snapshot": { … } } }`

## `POST /api/v1/universes/:universe_id/entries/:id/versions/:version/restore`

Restores snapshot as a new version (does not rewrite history).

**200:** `{ "entry": { … } }`
