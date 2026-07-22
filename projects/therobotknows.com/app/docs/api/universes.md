# Universes API

Base: `/api/v1/universes`  
Auth: Bearer required for all endpoints in v0.1.

Resource shape (detail):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "slug": "ashward-chronicles",
  "name": "The Ashward Chronicles",
  "description": "An epic fantasy set in the fractured Northern Reach…",
  "genre": "Fantasy Novel",
  "tone": "grim, lyrical",
  "config": {
    "genre": "Fantasy Novel",
    "tone": "grim, lyrical",
    "naming_conventions": "",
    "constraints": []
  },
  "status": "active",
  "entry_count": 24,
  "flag_count": 3,
  "connection_count": 47,
  "role": "owner",
  "created_by": "…",
  "inserted_at": "2026-03-01T10:00:00.000000Z",
  "updated_at": "2026-03-13T14:22:00.000000Z"
}
```

List items may omit full `config` (include counts + genre/tone).

---

## `GET /api/v1/universes`

List universes the caller is a member of.

**Query:** `page`, `per_page` (see conventions).

**200:**

```json
{
  "universes": [ /* universe summary */ ],
  "meta": { "page": 1, "per_page": 25, "total": 3, "total_pages": 1 }
}
```

---

## `POST /api/v1/universes`

Create a universe. Caller becomes the sole member with role `owner`.

**Body:**

```json
{
  "universe": {
    "name": "The Ashward Chronicles",
    "slug": "ashward-chronicles",
    "description": "…",
    "genre": "Fantasy Novel",
    "tone": "grim, lyrical",
    "config": {
      "genre": "Fantasy Novel",
      "tone": "grim, lyrical",
      "naming_conventions": "…",
      "constraints": ["…"]
    }
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | yes | 1–255 chars |
| `slug` | no | Auto from name if omitted; unique globally; `^[a-z0-9]+(?:-[a-z0-9]+)*$` |
| `description` | no | |
| `genre` | no | Also written into `config.genre` if config omitted |
| `tone` | no | Also written into `config.tone` |
| `config` | no | Defaults `{}` |

**201:** `{ "universe": { … } }`  
**422:** field errors (e.g. slug taken).

---

## `GET /api/v1/universes/:id_or_slug`

Show one universe. `:id_or_slug` is UUID or slug.

**200:** `{ "universe": { … } }`  
**403:** not a member  
**404:** missing or soft-deleted

---

## `PATCH /api/v1/universes/:id_or_slug`

Update settings (US-010, US-015). Role: `owner` or `editor`.

**Body:** partial `universe` object — same fields as create (except slug immutable after create in v0.1).

**200:** `{ "universe": { … } }`  
**403 / 404 / 422** as usual

---

## `DELETE /api/v1/universes/:id_or_slug`

Soft-delete (US-013). Role: `owner` only.

**200:** `{ "message": "Universe deleted" }`  
**403 / 404**

Hard purge is an async job (out of band); not exposed in v0.1 API.

---

## `GET /api/v1/universes/:id_or_slug/stats`

Dashboard stats (US-012).

**200:**

```json
{
  "stats": {
    "entry_count": 24,
    "entry_counts_by_type": {
      "character": 6,
      "location": 5,
      "event": 4,
      "faction": 3,
      "object": 2,
      "concept": 2,
      "rule": 2
    },
    "entry_counts_by_status": {
      "canon": 18,
      "draft": 3,
      "generated": 3
    },
    "flag_count": 3,
    "flag_counts_by_severity": {
      "error": 1,
      "warning": 1,
      "suggestion": 1
    },
    "connection_count": 47,
    "recent_activity": [
      {
        "id": "…",
        "type": "entry_created",
        "label": "New entry: The War of Stones",
        "at": "2026-03-12T18:00:00.000000Z",
        "entry_id": "…"
      }
    ]
  }
}
```

`recent_activity` may be empty until activity logging lands; clients must tolerate `[]`.

---

## Membership (read-only in v0.1)

### `GET /api/v1/universes/:id_or_slug/members`

**200:**

```json
{
  "members": [
    {
      "id": "…",
      "user_id": "…",
      "email": "user@example.com",
      "user_name": "elena",
      "role": "owner",
      "joined_at": "…"
    }
  ]
}
```

Invite/role mutation endpoints ship in M5 (US-091/US-092).
