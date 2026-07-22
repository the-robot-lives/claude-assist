# Versioning and Evolution

How to change a published API without stranding consumers: change classification, strategy selection, deprecation mechanics, and CI gates. Ends with a worked example.

## Change Classification

Classify every proposed change before deciding how to ship it. Be strict — "probably fine" changes break real clients.

| Classification | Examples | Ship as |
|----------------|----------|---------|
| **Additive (safe)** | New endpoint; new optional request field; new response field; new optional query param; new enum value in a *request* enum; loosening validation | Just ship; changelog entry |
| **Deprecating** | Marking a field/endpoint for removal while it still works | Ship + `Deprecation` header + docs + timeline |
| **Breaking** | Removing/renaming anything; type changes; new required field; narrowing validation; changing default behavior; **new enum value in a *response* enum**¹; changing error `type` URIs; auth scheme changes; tightening rate limits materially | Full evolution workflow below |

¹ Response-enum additions are breaking *unless* your contract documents that clients must tolerate unknown values (tolerant reader). Document this rule on day one and response enums become additive.

**Sneaky breaking changes** people misclassify as safe: reordering JSON is fine, but changing number precision, timestamp format, ID format/length, pagination page size defaults, or sort order all break real integrations.

## Strategy Decision Tree

```
Are all consumers internal and deployable by you?
├── YES → Additive-only, no explicit version. Coordinate the rare break via
│         deploy ordering. (GraphQL/gRPC: field-level evolution rules.)
└── NO (external/partner consumers)
    ├── Is the API surface still small/pre-GA?
    │   └── YES → Additive-only + explicit beta label ("v1beta", may break with notice)
    └── GA public API:
        ├── Can you afford per-account version pinning infra?
        │   ├── YES → Date-pinned header versioning (Stripe model):
        │   │         account pinned to e.g. 2026-07-15; upgrades opt-in;
        │   │         server translates between adjacent versions via shims
        │   └── NO  → URI versioning (/v1 → /v2), reserved for rare,
        │             whole-surface breaks; run both during migration window
        └── Either way: additive-only WITHIN a version, always
```

| Strategy | Granularity | Consumer effort | Operator effort | Notes |
|----------|-------------|-----------------|-----------------|-------|
| Additive-only | field | none | discipline + CI gate | The default everyone should exhaust first |
| Date-pinned header | per change-set | opt-in, incremental | translation shims per version | Best consumer UX; needs version registry |
| URI `/v1` | whole surface | full migration | run N surfaces in parallel | Simple to route; blunt instrument |
| proto/GraphQL schema evolution | field | none if rules followed | lint enforcement | `buf breaking`, schema checks — see below |

Anti-patterns: query-param versioning (`?version=2` — cache-hostile, easy to omit), per-endpoint version mixing (`/v1/orders` calling `/v2/customers` in one workflow), and "v2 as rewrite dumping ground" (v2 should be v1 minus mistakes, not a new product).

## Deprecation Mechanics

Timeline template (public API; compress for internal):

| Phase | Duration | Actions |
|-------|----------|---------|
| Announce | t0 | Changelog + migration guide; email affected consumers (identify via auth credentials — this is why anonymous APIs can't deprecate safely) |
| Deprecate | t0 → t0+6mo | `Deprecation: @1755302400` header (draft-ietf-httpapi-deprecation-header) + `Link: <migration-guide>; rel="deprecation"`; log + dashboard usage of the deprecated surface |
| Sunset | t0+6mo → t0+12mo | Add `Sunset: Sat, 15 Jul 2027 00:00:00 GMT` (RFC 8594); escalate outreach to remaining callers; optional scheduled brownouts (return 410 for 5 min windows) to flush inattentive integrations |
| Remove | t0+12mo | Return `410 Gone` with a problem-details body pointing at the migration guide — never 404 |

gRPC: `reserved 4, 9; reserved "old_field";` after removal so numbers/names are never reused. GraphQL: `@deprecated(reason:)` + field-usage telemetry, remove at zero usage or sunset date.

## CI Gates Against Accidental Breaks

| Surface | Tool | Gate |
|---------|------|------|
| OpenAPI | `oasdiff breaking old.yaml new.yaml` | Fail PR on any breaking diff not tagged with an approved evolution plan |
| protobuf | `buf breaking --against '.git#branch=main'` | Fail on wire/JSON breaking changes |
| GraphQL | `graphql-inspector diff` / Hive / Apollo schema checks | Fail on breaking; warn on deprecation-removal before sunset date |
| Any | Contract tests (consumer-driven, e.g. Pact) | Catch behavioral breaks schemas can't express |

The gate is what makes "additive-only" a policy instead of an aspiration.

## Worked Example: Splitting `customer.address` Into an Address List

Situation: v1 `Customer` has a single embedded `address` object; the business now needs multiple addresses with types (billing/shipping). Public REST API, ~200 partner integrations, additive-only policy with date-pinned headers available.

**Classification:** removing/repurposing `address` is breaking; adding `addresses` is additive.

**Plan:**

1. **Additive step (ships immediately):**
   - New sub-resource: `GET/POST /customers/{id}/addresses`, `PATCH/DELETE /customers/{id}/addresses/{aid}`
   - New response field `addresses: [...]` on Customer; `address` remains, now defined as "the default billing address" (a view over the list)
   - Writes to legacy `address` translate to upsert of the default billing entry — dual-read/dual-write bridge
2. **Deprecating step:** `address` marked deprecated in the spec (`deprecated: true` + description pointing at `addresses`); responses to callers *writing* `address` include `Deprecation` + `Link` headers
3. **Version-pinned removal:** new API version date `2027-01-15` drops `address` entirely; accounts upgrade opt-in; the version shim for older pins keeps synthesizing `address` from the list — no hard sunset needed because the shim is cheap
4. **CI:** oasdiff gate confirms step 1 is non-breaking; the `2027-01-15` version diff is tagged with this evolution plan

Consumer-visible cost: zero forced work; partners who never touch addresses never notice. That is the benchmark every evolution plan should aim for.
