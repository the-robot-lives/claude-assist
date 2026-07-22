# Entries API

Base: `/api/v1/universes/:universe_id/entries`  
`universe_id` = UUID or universe slug.  
Auth: Bearer; membership required (`viewer` read, `editor`/`owner` write).

## Entry resource

```json
{
  "id": "…",
  "universe_id": "…",
  "type": "character",
  "status": "canon",
  "title": "Kael Ashward",
  "slug": "kael-ashward",
  "excerpt": "Last master swordsmith of the Thornwall Guild…",
  "body": {
    "type": "doc",
    "content": []
  },
  "era": "Post-War of Stones",
  "region": "Northern Reach",
  "metadata": {},
  "tags": [
    { "id": "…", "name": "protagonist", "slug": "protagonist" }
  ],
  "word_count": 420,
  "version": 3,
  "created_by": "…",
  "inserted_at": "…",
  "updated_at": "…",
  "links": [
    {
      "id": "…",
      "source_entry_id": "…",
      "target_entry_id": "…",
      "relationship": "member of",
      "excerpt": null
    }
  ]
}
```

Notes:
- `body` accepts either a ProseMirror/Tiptap JSON document **or** a plain string
  (server stores string as a minimal doc or raw text field; prefer JSON for new clients).
- List endpoints may omit `body` and full `links` (include `excerpt`, tags, counts).

### Entry types

`character` | `location` | `event` | `faction` | `object` | `concept` | `rule`

### Entry statuses

`canon` | `draft` | `generated`

---

## `GET /api/v1/universes/:universe_id/entries`

**Query:**

| Param | Description |
|-------|-------------|
| `page`, `per_page` | Pagination |
| `type` | Filter by entry type |
| `status` | Filter by status |
| `tag` | Tag slug |
| `era`, `region` | Exact match |
| `q` | Simple title/excerpt search (full-text is M2.S2.4) |

**200:**

```json
{
  "entries": [ /* summary */ ],
  "meta": { "page": 1, "per_page": 25, "total": 24, "total_pages": 1 }
}
```

---

## `POST /api/v1/universes/:universe_id/entries`

Create entry (US-016). Default `status` = `draft` unless provided.

**Body:**

```json
{
  "entry": {
    "type": "character",
    "status": "draft",
    "title": "Kael Ashward",
    "slug": "kael-ashward",
    "excerpt": "…",
    "body": "…",
    "era": "…",
    "region": "…",
    "metadata": {},
    "tag_names": ["protagonist", "smith"]
  }
}
```

| Field | Required |
|-------|----------|
| `type` | yes |
| `title` | yes |
| others | no |

`tag_names` upserts tags in the universe and attaches them.

**201:** `{ "entry": { … } }`  
**422:** validation errors

---

## `GET /api/v1/universes/:universe_id/entries/:id`

**200:** `{ "entry": { … } }` including `body`, `tags`, `links`  
**404** if missing / deleted / wrong universe

---

## `PATCH /api/v1/universes/:universe_id/entries/:id`

Update entry (US-017). Increments `version` and records snapshot (once M2 versioning lands).

**Body:** partial `entry` object. Use `tag_names` to replace tag set when present.

**200:** `{ "entry": { … } }`

---

## `DELETE /api/v1/universes/:universe_id/entries/:id`

Soft-delete (US-018).

**200:** `{ "message": "Entry deleted" }`

---

## Status transitions (US-024)

### `POST /api/v1/universes/:universe_id/entries/:id/status`

**Body:**

```json
{ "status": "canon" }
```

Allowed transitions: see domain model. Invalid transition → **422**
`{ "error": "Invalid status transition from generated to draft" }` (example).

**200:** `{ "entry": { … } }`

---

## Links (US-022)

### `GET /api/v1/universes/:universe_id/entries/:id/links`

**200:** `{ "links": [ … ] }` — links where this entry is source or target.

### `POST /api/v1/universes/:universe_id/entries/:id/links`

Create outbound link from this entry.

```json
{
  "link": {
    "target_entry_id": "…",
    "relationship": "ruler of",
    "excerpt": "…"
  }
}
```

**201:** `{ "link": { … } }`

### `DELETE /api/v1/universes/:universe_id/links/:link_id`

**200:** `{ "message": "Link deleted" }`

### `POST /api/v1/universes/:universe_id/entries/:id/extract-links`

Body-scan link extraction (optional helper for the editor). Returns proposed
links without persisting (or with `persist: true`).

```json
{
  "proposals": [
    {
      "target_entry_id": "…",
      "target_title": "Thornwall",
      "relationship": "mentions",
      "excerpt": "…"
    }
  ]
}
```

---

## Tags (US-023)

### `GET /api/v1/universes/:universe_id/tags`

**200:** `{ "tags": [ { "id", "name", "slug", "entry_count" } ] }`

### `POST /api/v1/universes/:universe_id/tags`

```json
{ "tag": { "name": "protagonist" } }
```

**201:** `{ "tag": { … } }`

### `PUT /api/v1/universes/:universe_id/entries/:id/tags`

Replace tags on an entry:

```json
{ "tag_names": ["protagonist", "smith"] }
```

**200:** `{ "entry": { … } }`

---

## Templates (US-020)

### `GET /api/v1/entry-templates`

Global built-in templates (not universe-scoped).

**200:**

```json
{
  "templates": [
    {
      "type": "character",
      "name": "Character",
      "fields": ["aliases", "occupation", "affiliation"],
      "body_skeleton": "## Appearance\n\n## History\n\n## Relationships\n"
    }
  ]
}
```

One template per entry type in v0.1 (seven total).
