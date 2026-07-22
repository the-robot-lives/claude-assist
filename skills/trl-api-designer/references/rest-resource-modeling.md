# REST Resource Modeling

How to turn domain requirements into a REST resource surface: naming, URL structure, method semantics, relationships, actions that don't fit CRUD, and bulk operations. Ends with a worked example.

## From Operations to Resources

Start from the operation list in the brief, not from database tables. The mapping is: **every operation becomes a method on a noun**. If you can't find the noun, you haven't found the resource yet.

| Requirement phrasing | Resource extraction |
|----------------------|---------------------|
| "Users can place an order" | `POST /orders` |
| "Support can cancel an order" | Lifecycle transition — see Actions below |
| "Show a customer their invoices" | `GET /customers/{id}/invoices` or `GET /invoices?customer_id=` |
| "Export all transactions monthly" | Long-running job resource: `POST /exports` + `GET /exports/{id}` |
| "Notify partners when a payout settles" | Webhook event, not a REST endpoint — see error-and-pagination-patterns.md |

**Resource ≠ table.** A resource is a consumer-meaningful concept; it may aggregate several tables or expose a projection of one. Design the resource model for consumers, then hand the mapping problem to persistence design (trl-dba-db-designer-and-tuning).

## Naming and URL Rules

| Rule | Good | Bad |
|------|------|-----|
| Plural kebab-case nouns | `/payment-methods` | `/paymentMethod`, `/getPaymentMethods` |
| No verbs in paths | `POST /refunds` | `POST /createRefund` |
| Shallow nesting — max one level | `/customers/{id}/invoices` | `/customers/{id}/invoices/{iid}/lines/{lid}/taxes` |
| Nested for ownership, flat + filter for association | `/orders/{id}/items` (items can't exist alone) | nest `/customers/{id}/orders/{oid}` — orders have global IDs, use `/orders/{oid}` |
| Opaque, prefixed IDs | `pay_8fK2mQ` | sequential `41972` (enumerable, leaks volume) |
| Lowercase, hyphenated query params or snake_case — pick one, be consistent | `?created_after=` | mixed `?createdAfter=&page_size=` |

## Method and Status Semantics

| Method | Semantics | Idempotent | Success codes |
|--------|-----------|-----------|---------------|
| GET | Read, never mutates | Yes | 200 |
| POST | Create / non-idempotent action | No (unless Idempotency-Key) | 201 + Location, 202 for async |
| PUT | Full replace at known URI | Yes | 200 / 204 |
| PATCH | Partial update (JSON Merge Patch, RFC 7386, is the pragmatic default) | Not inherently | 200 |
| DELETE | Remove (or soft-delete transition) | Yes | 204, 202 for async |

Selection notes:
- Prefer **PATCH with merge-patch semantics** for updates; document that `null` clears a field.
- **PUT for client-chosen IDs** (`PUT /configs/{key}`), POST otherwise.
- Async work: `202 Accepted` + a job resource (`GET /jobs/{id}` → `status: pending|succeeded|failed`), never a 30-second blocking POST.

## Lifecycle Actions (the "cancel an order" problem)

Verbs that don't fit CRUD have three idiomatic encodings — in preference order:

| Pattern | Form | Use when |
|---------|------|----------|
| **State field via PATCH** | `PATCH /orders/{id}` `{"status": "cancelled"}` | Transition is simple, no parameters, few states |
| **Sub-resource action (POST verb as terminal segment)** | `POST /orders/{id}/cancel` `{"reason": "customer_request"}` | Transition takes parameters, has side effects, or needs its own error taxonomy — the pragmatic industry standard (Stripe, GitHub) |
| **Transition-as-resource** | `POST /refunds` `{"payment_id": ...}` | The transition produces a durable object worth listing/fetching later |

Model the state machine explicitly in the design doc:

```
order: draft ──submit──▶ pending ──approve──▶ confirmed ──ship──▶ shipped
              (POST /submit)     (auto)               (POST /shipments)
         draft|pending ──cancel──▶ cancelled   (POST /cancel, terminal)
```

Every transition endpoint documents: allowed source states, target state, and the 409/422 problem type returned on an illegal transition.

## Relationships, Expansion, Filtering

| Concern | Pattern |
|---------|---------|
| Reference by default | `{"customer_id": "cus_31aB"}` — not embedded objects |
| Opt-in expansion | `GET /invoices/inv_1?expand=customer,payment` (bounded list of expandable fields; never recursive) |
| Filtering | Flat query params with operator suffixes: `?status=paid&created_after=2026-06-01&amount_gte=1000` |
| Sorting | `?sort=-created_at,amount` (leading `-` = descending) |
| Sparse fields | Only add `?fields=` if payloads are demonstrably heavy — it complicates caching and codegen |

## Bulk and Batch Operations

| Need | Pattern | Notes |
|------|---------|-------|
| Create many | `POST /invoices/batch` with array body, respond 207-style per-item results | Cap batch size (e.g. 100); partial success must be expressible per item |
| Update many by filter | Avoid. Prefer client-side iteration or an async job resource | Filter-mutations are dangerous and hard to make idempotent |
| Import/export | Async job: `POST /imports` (file or URL) → `GET /imports/{id}` | Emit a webhook on completion |

Per-item batch response shape:

```json
{
  "results": [
    {"index": 0, "status": 201, "id": "inv_9a"},
    {"index": 1, "status": 422, "problem": {"type": ".../validation-error", "title": "Validation failed"}}
  ]
}
```

## Worked Example: Fulfillment Service

Brief: storefront places orders; warehouse staff pick and ship; customers track. Consumers: internal storefront (Next.js), warehouse tablet app, partner tracking feed.

**Resource model:**

| Resource | Path | Methods | Notes |
|----------|------|---------|-------|
| Order | `/orders`, `/orders/{id}` | GET, POST, PATCH | State machine: `pending → picking → packed → shipped → delivered`, `cancelled` terminal from pending/picking |
| Order items | `/orders/{id}/items` | GET | Read-only after creation (items set at POST /orders) |
| Cancel | `/orders/{id}/cancel` | POST | Body: `{"reason": enum}`; 409 `illegal-transition` from packed+ |
| Shipment | `/shipments`, `/shipments/{id}` | GET, POST | Transition-as-resource: creating a shipment moves order to `shipped`; carries tracking data worth fetching later |
| Pick list | `/pick-lists?status=open` | GET, PATCH | Warehouse projection over orders in `picking` |

Decisions worth noting:
- `cancel` is a sub-resource action because it takes a reason and has state-dependent failures.
- `Shipment` is a full resource (not `POST /orders/{id}/ship`) because partners fetch tracking independently of orders.
- Items are immutable post-create — changing an order means cancel + re-create, which keeps the state machine honest.

> Full end-to-end treatment including the OpenAPI spec: `worked-example-payments-api.md`.
