# Error and Pagination Patterns

The cross-cutting contract surfaces consumers integrate against hardest: RFC 9457 problem details, status-code selection, cursor pagination, rate limiting, idempotency, and webhook delivery. Ends with a worked example.

## RFC 9457 Problem Details

Every non-2xx response is `application/problem+json` (RFC 9457, which obsoletes RFC 7807):

```json
{
  "type": "https://api.example.com/problems/insufficient-funds",
  "title": "Insufficient funds",
  "status": 422,
  "detail": "Account acct_29x has balance 12.50 USD; charge requires 40.00 USD.",
  "instance": "/payments/pay_7Yq2",
  "balance": "12.50",
  "currency": "USD",
  "request_id": "req_01J9ZKM3"
}
```

| Member | Contract rule |
|--------|---------------|
| `type` | Stable URI, the machine-readable identity — clients switch on it; changing one is a breaking change. Dereferenceable to human docs is ideal but not required |
| `title` | Short, stable per type; never localized per-request |
| `detail` | Human-readable, may vary, **never parsed by clients** — put data in extensions instead |
| `status` | Mirrors the HTTP status |
| extensions | Typed, documented members (`balance`, `errors[]`, `retry_after`) — this is where structured data lives |
| `request_id` | Always include a correlation ID extension for support |

**Validation errors** get one type with an `errors` extension array:

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "errors": [
    {"pointer": "/amount", "code": "min", "message": "must be >= 50"},
    {"pointer": "/currency", "code": "enum", "message": "must be one of USD, EUR"}
  ]
}
```

**Error catalog:** maintain the list of `type` URIs in the design doc/spec with: status, retryable (yes/no/after-delay), and required extensions. The catalog is part of the versioned contract.

## Status Code Selection

| Situation | Code | Notes |
|-----------|------|-------|
| Malformed syntax (bad JSON) | 400 | |
| Well-formed but semantically invalid | 422 | The validation-error workhorse |
| Missing/invalid credentials | 401 | + `WWW-Authenticate` |
| Authenticated but not allowed | 403 | Use 404 instead when resource *existence* is sensitive |
| No such resource | 404 | |
| State conflict (illegal transition, duplicate) | 409 | e.g. cancelling a shipped order |
| Idempotency key reuse with different body | 422 (Stripe) or 409 | Pick one, document it |
| Rate limited | 429 | + `Retry-After` |
| Upstream/internal failure | 502 / 500 | Problem body with `request_id`, no internals leaked |
| Removed after sunset | 410 | Problem body links migration guide |

## Pagination

**Default: cursor.** Offset only for small, static admin datasets (see the SKILL.md comparison table).

Envelope shape:

```json
{
  "data": [ {"id": "pay_7Yq2", "...": "..."} ],
  "has_more": true,
  "next_cursor": "Y3JlYXRlZF9hdDoyMDI2LTA3LTAxVDEyOjAwOjAwWjppZDpwYXlfN1lxMg"
}
```

| Rule | Why |
|------|-----|
| Cursors are **opaque** (base64 of sort-key values, optionally HMAC'd) | Clients that parse cursors freeze your implementation |
| Cursor encodes the full sort key including a unique tiebreaker (`created_at` + `id`) | Non-unique sort keys skip/duplicate rows at boundaries |
| `limit` capped server-side (e.g. max 100, default 25) | Unbounded pages are a DoS vector |
| Sort order is fixed per endpoint or explicitly parameterized — cursor is only valid for the sort it was issued under | Reject mismatches with 400 |
| Don't return `total_count` on cursor endpoints unless cheap | COUNT(*) on large filtered sets is the top pagination-induced DB incident |

## Rate Limiting

Contract, not just infrastructure — document limits and expose state:

```
RateLimit-Limit: 1000
RateLimit-Remaining: 741
RateLimit-Reset: 1752585600
Retry-After: 30            (on 429 only)
```

(`RateLimit-*` per draft-ietf-httpapi-ratelimit-headers; legacy `X-RateLimit-*` still common — pick one and document.)

| Decision | Default |
|----------|---------|
| Keying | Per credential (not per IP) for authenticated APIs |
| Granularity | Global per-key + stricter buckets for expensive endpoints (search, export) |
| Algorithm | Token bucket (allows bursts); sliding window if burst is unacceptable |
| 429 body | Problem details `type: .../rate-limited` with `retry_after` extension |

## Idempotency

Any POST with side effects that a client would retry (payments, order creation, sends) accepts an idempotency key:

```
POST /payments
Idempotency-Key: 0b4f2c9e-4a3d-4f1a-9d5e-8e2f6a1b7c3d
```

| Rule | Detail |
|------|--------|
| Server stores key → (request hash, response) for a window (24h typical) | Replay returns the **stored response**, same status code |
| Same key + different body | 422/409 problem `idempotency-key-reuse` — never process |
| Key scope | Per credential, per endpoint |
| Concurrent duplicate in flight | Second request waits or gets 409 `request-in-progress` |
| GET/PUT/DELETE | Already idempotent — no key needed |

## Webhooks / Event Delivery

The consumer-side contract for push:

| Concern | Pattern |
|---------|---------|
| Envelope | `{"id": "evt_...", "type": "payment.succeeded", "created": ..., "api_version": "2026-07-15", "data": {...}}` — event `type` names are `resource.event`, versioned with the API |
| Signing | HMAC-SHA256 over `timestamp + "." + raw_body`; header `X-Signature: t=1752585600,v1=<hex>`; consumers reject skew > 5 min (replay defense) |
| Delivery | At-least-once; retries with exponential backoff + jitter over ~72h; consumer must dedupe on `id` |
| Ordering | **Not guaranteed** — say so loudly; consumers reconcile via `GET` on the resource, treating events as invalidation hints |
| Consumer response | 2xx within a short timeout (5-10s) = ack; anything else = retry. Consumers should enqueue and ack, not process inline |
| Fat vs thin payloads | Thin (`id` + type, consumer fetches) when payloads carry sensitive data or ordering matters; fat otherwise |

## Worked Example: Search + Export Endpoints for a Ticketing API

Brief: `/tickets` supports filtered search for a dashboard (fast pages, changing data) and a nightly full export for a data team.

**Search:** `GET /tickets?status=open&assignee_id=usr_3&sort=-updated_at&limit=50&cursor=...`
- Cursor over `(updated_at, id)`; `total_count` omitted (filtered COUNT over 40M rows) — the dashboard shows "50+" instead
- Dedicated rate bucket: 60/min vs the global 1000/min, documented in the spec

**Export:** not paginated-GET-in-a-loop. `POST /exports {"resource": "tickets", "format": "ndjson"}` with `Idempotency-Key` → `202` + job resource → `ticket_export.completed` webhook with a signed, expiring download URL.
- Rationale recorded: paging 40M rows via cursors holds a consistent-ish view for hours and hammers the DB; a snapshot job is cheaper and gives the data team a stable artifact.

**Errors exercised:** `422 validation-error` (bad sort field, with `errors[].pointer`), `429 rate-limited` (`retry_after: 22`), `409 request-in-progress` (duplicate export key while job 1 runs).
