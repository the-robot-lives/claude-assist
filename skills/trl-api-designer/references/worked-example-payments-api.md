# Worked Example: Payments API

End-to-end walkthrough of the four-phase design process applied to a payments/billing REST API — from requirements through OpenAPI 3.1 spec and checklist review. Follow along with `assets/api-brief-worksheet.md` and `assets/api-design-checklist.md`.

---

## Phase 1: Brief

Filled worksheet (condensed):

| Field | Answer |
|-------|--------|
| Domain | Payments and billing for a SaaS platform: charge customers, issue refunds, list transaction history, notify on settlement |
| Consumers | (a) First-party Next.js dashboard, (b) ~30 partner backends integrating checkout, (c) internal Phoenix `ledger` service, (d) partner systems needing settlement notifications |
| Core operations | Create payment, fetch/list payments, refund (full/partial), list refunds, manage payment methods, receive settlement events |
| Non-functional | Money must never double-charge on retry; partners are on unreliable networks; PCI scope minimized (no raw PANs — tokenized `source_id` from the PSP); 7-year auditability |
| Compatibility constraints | Greenfield — no legacy clients. Public from day one → evolution policy needed at birth |
| Explicitly out of scope | PSP integration internals, ledger schema (→ trl-dba-db-designer-and-tuning), invoicing (separate API) |

## Phase 2: Model

**Protocol decision (from SKILL.md table):** third-party partner consumers + request/response CRUD → **REST + OpenAPI 3.1** for the public surface; settlement notifications → **webhooks**; internal `ledger` calls reuse the REST surface for now (gRPC deferred until latency data justifies it). *Rationale logged: partner heterogeneity rules out GraphQL as the primary contract.*

**Resource model:**

| Resource | Path | Methods | Notes |
|----------|------|---------|-------|
| Payment | `/payments`, `/payments/{id}` | POST, GET, GET(list) | Immutable after terminal state |
| Refund | `/refunds`, `/refunds/{id}`; list filter `?payment_id=` | POST, GET, GET(list) | Transition-as-resource: a refund is a durable object partners reconcile against — not `POST /payments/{id}/refund` |
| Payment method | `/customers/{id}/payment-methods`, `/payment-methods/{id}` | GET(list), POST, DELETE | Nested create under customer (ownership); global fetch by ID |
| Events (webhooks) | n/a — outbound | — | `payment.succeeded`, `payment.failed`, `refund.succeeded`, `payout.settled` |

**Payment state machine:**

```
pending ──psp-auth──▶ succeeded ──▶ (refundable until fully refunded)
   │
   └──psp-decline──▶ failed        (terminal)
```

No client-driven transitions on Payment itself — the PSP drives it; clients observe via GET + webhooks. Refund has its own `pending → succeeded | failed`.

Amounts are **integer minor units + ISO currency** (`{"amount": 4000, "currency": "USD"}`) — floats never appear in the contract.

## Phase 3: Contract Decisions

Decision log:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Versioning | Additive-only + tolerant-reader enum rule documented at birth; date-pinned header versioning (`API-Version`) reserved and documented but unused until the first break | Public from day one; cheapest option that leaves the Stripe-model door open |
| Auth | Partners: API keys `nz_live_*`/`nz_test_*`, scopes `payments:read`, `payments:write`, `refunds:write`, `payment_methods:write`; dashboard: OIDC+PKCE; tenant from credential, never from body | See `auth-patterns.md` worked example — same system |
| Idempotency | `Idempotency-Key` header **required** on `POST /payments` and `POST /refunds`; 24h window; key reuse with different body → 422 `idempotency-key-reuse` | "Never double-charge on retry" is a hard requirement |
| Pagination | Cursor over `(created_at, id)`, `limit` ≤ 100 default 25, no `total_count` | Transaction lists grow unboundedly |
| Errors | RFC 9457; catalog below | |
| Rate limits | 1000/min per key global; 100/min on `POST /payments`; `RateLimit-*` headers | Charge creation is the abuse surface |
| Webhooks | HMAC-signed (`t=`,`v1=` scheme), thin-ish envelope with full resource in `data`, at-least-once, dedupe on `evt_` id, no ordering guarantee | Partners asked for fat payloads; acceptable since payloads aren't PCI-scoped |

**Error catalog (excerpt):**

| `type` (…/problems/) | Status | Retryable | Extensions |
|----------------------|--------|-----------|------------|
| `validation-error` | 422 | no | `errors[]{pointer,code,message}` |
| `insufficient-funds` | 422 | no (user action) | `decline_code` |
| `card-declined` | 422 | no | `decline_code` |
| `idempotency-key-reuse` | 422 | no | `original_request_id` |
| `request-in-progress` | 409 | after delay | `retry_after` |
| `refund-exceeds-remaining` | 422 | no | `remaining` |
| `rate-limited` | 429 | after delay | `retry_after` |
| `psp-unavailable` | 502 | yes | `request_id` |

**Spec:** authored per `openapi-workflow.md` — the fragment there (createPayment, Payment schema, Problem responses, `payment.succeeded` webhook) is drawn from this API. Full spec lands at `api/openapi.yaml`: 9 operations, 3 tags, 7 schemas, 2 security schemes, 4 webhook events. Highlights:

- `Payment.status` enum carries the tolerant-reader note ("clients MUST tolerate unknown future values") — making future states like `disputed` additive
- One `Payment` schema with `readOnly` markers serves request and response
- `POST /refunds` example shows partial refund: `{"payment_id": "pay_7Yq2", "amount": 1500}` — omitting `amount` means full remaining
- Every operation carries named examples; `prism mock` gave the dashboard team a working backend in week one

## Phase 4: Review

`assets/api-design-checklist.md` walk — findings:

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | Critical | `DELETE /payment-methods/{id}` returned 204 even when the method backed an active subscription (data-integrity foot-gun) | Changed to 409 `payment-method-in-use` with `subscription_ids` extension; documented detach-first flow |
| 2 | Major | No way to reconcile missed webhooks after an outage | Added `GET /events?after=evt_...` (cursor) — events became a listable resource; webhook remains the push channel |
| 3 | Major | `source_id` lifetime undocumented — partners would cache expired PSP tokens | Added `expires_at` to PaymentMethod + `payment-method-expired` problem type |
| 4 | Minor | Mixed `customerId`/`customer_id` in two examples | Normalized snake_case; spectral rule added |

Checklist score after fixes: 41/43 (2 N/A — no offset pagination, no URI versioning). Sign-off recorded in the tracker; resource model handed to **trl-dba-db-designer-and-tuning** for ledger/payments schema; spec handed to **trl-technical-writer** for the partner docs site.

## Lessons This Example Encodes

1. **Refund-as-resource beat refund-as-action** because partners reconcile refunds independently — consumer need, not REST purism, decided it.
2. **The review caught the money bugs** (findings 1–3 all surfaced in Phase 4, before any code). The checklist is not a formality.
3. **Idempotency and tolerant-reader rules were free at design time** and would each have been a breaking retrofit six months in.
4. **The mock server made the contract real** — dashboard integration feedback reshaped the list-filter params before the backend team wrote a handler.
