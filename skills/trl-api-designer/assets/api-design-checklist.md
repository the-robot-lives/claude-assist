# API Design Review Checklist

The Phase 4 gate. Fill one copy per API. Mark each item **Pass / Fail / N/A** and log every Fail in the tracker's findings table with a severity (critical / major / minor). Ship threshold: zero open critical findings, all majors resolved or scheduled.

- **API**: {name}
- **Contract file/commit**: {path @ sha}
- **Reviewer**: {name}  **Date**: {date}

## 1. Resource Model and Naming

| # | Check | P/F/NA |
|---|-------|--------|
| 1.1 | Paths are plural kebab-case nouns; no verbs in paths (lifecycle actions excepted) | |
| 1.2 | Nesting ≤ 1 level; nesting used only for ownership, not association | |
| 1.3 | IDs are opaque and prefixed; nothing enumerable or volume-leaking | |
| 1.4 | Field naming convention (snake_case/camelCase) is single and consistent | |
| 1.5 | Resources with lifecycles have documented state machines incl. illegal-transition errors | |
| 1.6 | Money as integer minor units + currency; timestamps ISO 8601 UTC; no floats for money | |

## 2. Methods and Status Codes

| # | Check | P/F/NA |
|---|-------|--------|
| 2.1 | GET never mutates; PUT/DELETE idempotent; PATCH semantics (merge-patch) documented incl. null-clears | |
| 2.2 | POST create returns 201 + Location (or 202 + job resource for async) | |
| 2.3 | Long-running operations (>~5s) are async job resources, not blocking calls | |
| 2.4 | 401 vs 403 vs 404 usage deliberate; existence-hiding decision documented for tenant-scoped resources | |
| 2.5 | 409 vs 422 usage consistent and documented | |

## 3. Errors

| # | Check | P/F/NA |
|---|-------|--------|
| 3.1 | All non-2xx responses are RFC 9457 `application/problem+json` | |
| 3.2 | Error catalog exists: every `type` URI with status, retryability, extensions | |
| 3.3 | Validation errors carry per-field `errors[]` with pointers | |
| 3.4 | Every response includes a correlation/request ID | |
| 3.5 | No internal details (stack traces, SQL, upstream names) leak in any error body | |

## 4. Pagination, Filtering, Limits

| # | Check | P/F/NA |
|---|-------|--------|
| 4.1 | Every growable list is paginated; cursor unless offset is justified in the decision log | |
| 4.2 | Cursors opaque; sort key includes a unique tiebreaker | |
| 4.3 | `limit` has a server-enforced max and a documented default | |
| 4.4 | `total_count` absent, or its cost accepted in the decision log | |
| 4.5 | Rate limits documented per bucket; `RateLimit-*` headers + 429 with `Retry-After` | |

## 5. Idempotency and Concurrency

| # | Check | P/F/NA |
|---|-------|--------|
| 5.1 | Every side-effecting POST a client would retry accepts (or requires) `Idempotency-Key` | |
| 5.2 | Key-reuse-with-different-body and concurrent-duplicate behaviors specified | |
| 5.3 | Lost-update protection where needed (ETag/If-Match or version field) | |

## 6. Auth

| # | Check | P/F/NA |
|---|-------|--------|
| 6.1 | Auth pattern per consumer type matches the selection matrix (or deviation logged) | |
| 6.2 | Every operation declares required scopes in the spec | |
| 6.3 | Tenant derived from credential — never from a client-supplied body/query field | |
| 6.4 | Credentials never in query params; key format supports secret scanning; rotation is zero-downtime | |
| 6.5 | Token TTLs and refresh/rotation policy documented | |

## 7. Versioning and Evolution

| # | Check | P/F/NA |
|---|-------|--------|
| 7.1 | Versioning strategy chosen and recorded before GA (not deferred) | |
| 7.2 | Tolerant-reader rule for response enums documented | |
| 7.3 | Deprecation policy defined (headers, timeline, comms channel to identified consumers) | |
| 7.4 | Breaking-change CI gate configured (oasdiff / buf breaking / schema checks) | |

## 8. Webhooks / Events (if applicable)

| # | Check | P/F/NA |
|---|-------|--------|
| 8.1 | Events signed (HMAC + timestamp); verification contract documented for consumers | |
| 8.2 | At-least-once + dedupe-on-id + no-ordering-guarantee stated explicitly | |
| 8.3 | Retry/backoff schedule documented; a pull-based reconciliation path exists (events list or resource GET) | |
| 8.4 | Event type names follow `resource.event`; payload versioned with the API | |

## 9. Spec Quality

| # | Check | P/F/NA |
|---|-------|--------|
| 9.1 | OpenAPI 3.1 (or SDL/proto) lint-clean; accepted exceptions documented inline | |
| 9.2 | Every operation: unique verb-first operationId, exactly one tag, all realistic response codes | |
| 9.3 | ≥1 named request and response example per operation; examples validate against schemas | |
| 9.4 | Shared components used for problems, pagination params, security — no copy-paste schemas | |
| 9.5 | Spec matches any existing implementation (drift check run) | |

## Result

- **Score**: {passes} / {applicable}
- **Critical findings open**: {n}
- **Verdict**: ☐ Approved ☐ Approved with conditions ☐ Rework
- **Notes**:
