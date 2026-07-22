# M6 — Telemetry, SDKs & Enterprise

**Impl-plan stages:** 10, 10+, 11, 12 · **Stories:** 19

## Mission

Extend the platform outward: ingest production telemetry (OTLP receiver, span↔run-step
correlation, query/search, auto-flagging), ship the three SDK cores + webhooks that
embed CodeFresh in customers' codebases, and land enterprise tenancy (SSO, audit
export). Lanes are independent except that the SDK OTel bridge (US-094) consumes Lane
A's receiver.

## Entry criteria

- M5 exit: flagged-captures promotion paths exist (auto-flagging feeds them).
- M0: OTLP receiver contract frozen; API tokens live (SDK auth).
- M4: stable public API surface for SDK query helpers.

## Exit criteria

- OTLP gRPC receiver ingests spans; spans correlate to run_steps; attribute query,
  span-tree drilldown, and semantic search work; retention/sampling administrable.
- Auto-flag rules capture production interactions into the M5 review surfaces (US-106
  auto mode complete).
- Python, Elixir, and TypeScript SDKs install, authenticate, trigger runs, query
  results, and bridge OTel spans; webhook subscriptions deliver.
- SSO via SAML/OIDC and audit log export pass an enterprise-checklist review.

## Lane A — OTel ingestion & auto-flagging (9 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/otel/`, `autoflag`, span
search/drilldown screens.

| Story | Title | Pri |
|---|---|---|
| US-081 | Stand up an OTLP gRPC receiver endpoint for inbound agent spans | P1 |
| US-082 | Correlate inbound OTel spans to run_steps | P1 |
| US-098 | Query OTel spans by attribute | P1 |
| US-099 | Drill down from a run step into its OTel span tree | P1 |
| US-100 | Semantic search over OTel span names and messages | P1 |
| US-131 | OTel partition + retention admin | P2 |
| US-132 | OTLP ingest sampling configuration | P2 |
| US-147 | Auto-flagging rules for production captures (finalizes US-106 auto mode) | P2 |
| US-133 | ClickHouse mirror for OTel spans and logs | P3 |

## Lane B — SDKs & webhooks (8 stories)

**Zone / exclusive surfaces:** `sdks/{python,elixir,typescript}/`,
`app/backend/lib/codefresh/webhooks/`.

| Story | Title | Pri |
|---|---|---|
| US-091 | Python SDK core — install, authenticate, trigger runs | P1 |
| US-092 | Elixir SDK core — install, authenticate, trigger runs | P1 |
| US-093 | TypeScript SDK core — install, authenticate, trigger runs | P1 |
| US-094 | SDK OTel bridge helper for emitting spans to CodeFresh (needs Lane A receiver) | P1 |
| US-095 | SDK query helpers for runs, steps, and scores | P1 |
| US-144 | SDK webhook subscriptions | P2 |
| US-145 | React hooks package for run state | P3 |
| US-146 | SDK publish for Deno and Bun runtimes | P3 |

## Lane C — Enterprise tenancy (2 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/enterprise/` (sso_config),
audit-export surfaces, org settings screens.

| Story | Title | Pri |
|---|---|---|
| US-142 | SSO via SAML / OIDC | P2 |
| US-143 | Audit log export | P2 |

## Cross-lane integration task

An app instrumented with the Python SDK's OTel bridge emits production spans; an
auto-flag rule captures a low-scoring interaction; it appears in the flagged-captures
library and promotes to a dataset entry; a webhook fires on the resulting dataset run —
telemetry in, eval out, notification delivered, under an SSO-authenticated org.
