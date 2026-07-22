# API Conventions

## Base path & versioning

- All product JSON APIs: **`/api/v1/...`**
- Health (unversioned): `GET /health`
- Breaking changes require a new major prefix (`/api/v2`); additive fields are non-breaking.

## Authentication

| Mechanism | Detail |
|-----------|--------|
| Header | `Authorization: Bearer <access_token>` |
| Issuer | Phoenix Guardian (backend) |
| Obtain | `POST /api/v1/auth/login`, `/register`, `/refresh`, magic-link/OTP/SSO exchange |
| Refresh | `POST /api/v1/auth/refresh` with `{ "refresh_token": "..." }` → new access (+ optional refresh) |

Unauthenticated requests to protected routes → **401** with error envelope.

Public/read-anonymous surfaces (M5 public codex) are documented per-endpoint when introduced.

## Content type

- Request bodies: `Content-Type: application/json`
- Responses: `application/json; charset=utf-8`

## Resource envelopes

Successful responses wrap the primary resource in a named key:

```json
{ "universe": { "id": "...", "name": "..." } }
{ "universes": [ ... ] }
{ "entry": { ... } }
{ "entries": [ ... ] }
```

### Pagination (list endpoints)

Query params:

| Param | Default | Max | Description |
|-------|---------|-----|-------------|
| `page` | `1` | — | 1-based page index |
| `per_page` | `25` | `100` | Page size |

List response:

```json
{
  "universes": [ ... ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 42,
    "total_pages": 2
  }
}
```

Endpoints that are unpaginated in v0.1 (small collections) omit `meta` and may return the full array.

## Error envelope

### Single error

```json
{ "error": "Human-readable message" }
```

HTTP status conveys class: `400` bad request, `401` unauth, `403` forbidden,
`404` not found, `409` conflict, `422` validation, `429` rate limit, `500` server.

### Field errors (validation)

```json
{
  "errors": {
    "name": ["can't be blank"],
    "slug": ["has already been taken"]
  }
}
```

Clients should prefer `errors` when present; fall back to `error` string.

## Identifiers

- Primary keys: **UUID** strings in JSON.
- Universes also expose a unique **`slug`** for URL routing; clients may call
  show/update with either UUID or slug where noted.
- Timestamps: ISO-8601 UTC (`2026-03-13T14:22:00.000000Z`).

## Naming

- JSON fields: **snake_case** (matches backend).
- Frontend TypeScript models may camelCase at the boundary; the API client is
  responsible for mapping if needed. v0.1 client may keep snake_case on wire
  types under `src/types/api/` and map to UI types.

## Idempotency & soft delete

- `DELETE` on universes/entries is **soft-delete** unless noted.
- Soft-deleted resources return **404** to non-admin list/show by default.

## Rate limiting

Auth-sensitive routes use Hammer rate limits (existing platform plugs).
Exceeding limits → **429** `{ "error": "Rate limit exceeded" }`.
