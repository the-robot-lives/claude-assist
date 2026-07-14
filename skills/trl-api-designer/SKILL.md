---
name: trl-api-designer
description: >
  Design and evolve API contracts — REST resource modeling, GraphQL schemas, gRPC/protobuf,
  OpenAPI 3.1 schema-first workflows, versioning, auth, pagination, RFC 9457 errors, and
  webhooks. Use this skill (or `/trl-api-designer`) to design a new API, review an endpoint
  surface, plan versioning or deprecation, choose REST vs GraphQL vs gRPC, or author an
  OpenAPI spec — even if they don't say "API design." Also trigger on: REST, GraphQL,
  OpenAPI, swagger, contract-first, endpoint design, pagination, webhook design, API review.
  NOT for MCP server design (trl-mcp-architect/builder/forge), database schema design
  (trl-dba-db-designer-and-tuning), or implementing the backend service itself.
---

# API Designer

Contract-first design and evolution of REST, GraphQL, and gRPC APIs — from requirements to reviewed OpenAPI spec.

## Overview

API Designer is the **contract phase** of service development. The API contract is a public promise: cheap to change before consumers exist, ruinously expensive after. This skill front-loads every consequential decision — protocol, resource model, auth, versioning, errors, pagination — into a reviewable design before implementation begins. It provides:

- **Protocol and style selection** — REST vs GraphQL vs gRPC vs webhooks/events, decided by consumer shape, not fashion
- **Resource and schema modeling** — REST resource design, GraphQL SDL (federation-aware), protobuf service definitions
- **OpenAPI 3.1 schema-first workflow** — authoring, linting, mocking, and drift prevention
- **Versioning and evolution planning** — URI/header/schema-evolution strategies, deprecation policy, breaking-change gates
- **Cross-cutting patterns** — auth selection, cursor/offset pagination, RFC 9457 error taxonomy, rate limiting, idempotency keys, webhook delivery
- **Structured API review** — checklist-driven audits of existing surfaces with severity-ranked findings

## Core Philosophy

1. **The contract is the product.** Consumers integrate against the spec, not the code. Design the spec first, review it like production code, and generate everything else (docs, mocks, client SDKs, server stubs) from it.

2. **Breaking changes are a tax on every consumer.** Additive evolution is nearly free; breaking evolution costs every integrator a migration. Design so that the additive path stays open: optional fields, extensible enums, tolerant readers.

3. **Boring beats clever.** A predictable REST surface with cursor pagination and RFC 9457 errors is worth more than an inventive one. Novelty in an API is a cost the consumer pays forever.

4. **Errors are part of the contract.** The failure surface gets integrated against as heavily as the success surface. Define the error taxonomy — types, retryability, problem-details shape — with the same rigor as the happy path.

5. **Design for the second consumer.** The first consumer's needs are known; the second's aren't. Filtering, pagination, idempotency, and versioning hooks cost little up front and are near-impossible to retrofit cleanly.

## When to Use This Skill

- **Designing a new API** — full phased design: brief → protocol → resource model → contract → review
- **Reviewing an existing API** — checklist audit of a spec, route file, or live surface; severity-ranked findings
- **Planning API evolution** — adding capability, splitting resources, or deprecating fields without stranding clients
- **Choosing a protocol** — REST vs GraphQL vs gRPC vs event/webhook delivery for a given consumer mix
- **Authoring an OpenAPI 3.1 spec** — schema-first authoring with reusable components, examples, and lint gates
- **Defining cross-cutting standards** — org-wide error format, pagination, versioning, and webhook conventions

> For MCP server tool-surface design, see **trl-mcp-architect** (`references/tool-manifest-guide.md`) — MCP tools are LLM-facing contracts with different design rules.
> For the persistence schema behind your resources, see **trl-dba-db-designer-and-tuning** — resource models and table models should be designed separately and mapped deliberately.
> For publishing API reference docs from the finished spec, see **trl-technical-writer** (`references/`).

## Protocol Selection

Choose the protocol from consumer shape and interaction pattern — first table wins:

| If your consumers are... | And the interaction is... | Choose | Why |
|--------------------------|---------------------------|--------|-----|
| Third parties, unknown clients, browsers | Request/response CRUD | **REST + OpenAPI 3.1** | Ubiquitous tooling, cacheable, self-describing, easiest to document and version |
| One frontend team iterating fast over rich object graphs | Flexible reads, varied views | **GraphQL** | Client-driven selection kills over/under-fetching; one round trip per view |
| Internal services, polyglot, latency-sensitive | Service-to-service RPC, streaming | **gRPC/protobuf** | Binary framing, codegen contracts, bidirectional streaming, deadline propagation |
| Systems reacting to state changes | Push, async | **Webhooks / events** | Consumers shouldn't poll; deliver signed events with retries |
| Mixed: partners + your own frontend | Both of the above | **REST core + optional GraphQL BFF** | Public contract stays boring; frontend gets flexibility at the edge |

Hybrid is normal: REST for the public surface, gRPC between internal services, webhooks for notifications. Full trade-off analysis and gRPC/protobuf modeling in `references/rest-resource-modeling.md` and `references/graphql-schema-design.md`.

## Versioning Strategy

| Strategy | Form | Best for | Cost |
|----------|------|----------|------|
| **Additive-only (no explicit version)** | Never break; only add optional fields/endpoints | Internal APIs, GraphQL, early-stage products | Requires discipline + tolerant-reader clients; some designs can't stay additive forever |
| **URI versioning** | `/v1/payments` → `/v2/payments` | Public REST with third-party consumers | Coarse-grained; whole-surface migration; two surfaces to run |
| **Header/media-type versioning** | `API-Version: 2026-07-15` (date-pinned) | Evolving public APIs (Stripe model) | More infra (version pinning per account); best-in-class consumer experience |
| **Schema evolution (protobuf/GraphQL)** | Reserved field numbers, `@deprecated` directives | gRPC and GraphQL surfaces | Governed by field-level rules, not URL; needs lint enforcement (buf breaking, GraphQL schema checks) |

Default recommendation: **additive-only until you can't, then date-pinned header versioning for public REST**. URI `/v1` is acceptable as a one-time escape hatch. Never mix strategies within one API. Full decision tree, deprecation policy templates, and sunset mechanics (RFC 8594 `Sunset` header, `Deprecation` header) in `references/versioning-and-evolution.md`.

## Pagination Choice

| Criterion | Offset (`?page=3&per_page=50`) | Cursor (`?after=cur_9f8e&limit=50`) |
|-----------|-------------------------------|--------------------------------------|
| Data changes while paging | Skips/duplicates rows | Stable |
| Deep pages on large tables | O(n) scan — degrades | O(log n) with keyed index |
| "Jump to page 47" | Yes | No |
| Implementation cost | Trivial | Needs an opaque, stable sort key |
| **Use for** | Small, static admin lists | **Everything else — the default** |

Default: **cursor pagination with opaque cursors** and a `next_cursor`/`has_more` envelope. Payload shapes and cursor-encoding rules in `references/error-and-pagination-patterns.md`.

## Auth Selection

| Consumer | Pattern | Notes |
|----------|---------|-------|
| Your own SPA/mobile app | **OIDC Authorization Code + PKCE** | Short-lived access tokens; refresh via secure rotation |
| Third-party apps acting for users | **OAuth 2.1 authorization code** | Scoped consent; never password grant (removed in 2.1) |
| Server-to-server (partner backends) | **OAuth client credentials** or **API keys** | API keys acceptable when scoping is coarse; hash at rest, prefix for identification (`sk_live_...`) |
| Internal service mesh | **mTLS** (often mesh-provided) + workload identity | Transport identity; combine with per-service authz |
| Webhook deliveries (you → consumer) | **HMAC signature header** + timestamp | e.g. `X-Signature: t=...,v1=hex(hmac_sha256(secret, t + "." + body))`; reject stale timestamps |

Scope design, token lifetimes, key rotation, and multi-tenant authz patterns in `references/auth-patterns.md`.

## Error Taxonomy (RFC 9457)

Every error response is `application/problem+json`:

```json
{
  "type": "https://api.example.com/problems/insufficient-funds",
  "title": "Insufficient funds",
  "status": 422,
  "detail": "Account acct_29x has balance 12.50 USD; charge requires 40.00 USD.",
  "instance": "/payments/pay_7Yq2",
  "balance": "12.50",
  "request_id": "req_01J9ZK"
}
```

Rules: stable `type` URIs form the machine-readable error catalog; `detail` is human-readable and never parsed; extension members carry structured data; retryability is documented per type. Full taxonomy, status-code selection table, and validation-error shape in `references/error-and-pagination-patterns.md`.

## The Design Process

```
Phase 1: BRIEF          Phase 2: MODEL           Phase 3: CONTRACT        Phase 4: REVIEW
┌───────────────┐      ┌────────────────┐       ┌────────────────┐      ┌────────────────┐
│ consumers      │      │ resources +    │       │ OpenAPI 3.1 /  │      │ checklist audit│
│ operations     │─────▶│ relationships  │──────▶│ SDL / proto    │─────▶│ + lint + mock  │
│ constraints    │      │ state machines │       │ errors, auth,  │      │ sign-off       │
│ (worksheet)    │      │ protocol pick  │       │ paging, hooks  │      │                │
└───────────────┘      └────────────────┘       └────────────────┘      └────────────────┘
```

| Phase | Output | Reference |
|-------|--------|-----------|
| 1. Brief | Filled `assets/api-brief-worksheet.md` | — |
| 2. Model | Resource/entity table, protocol decision, state machines | `rest-resource-modeling.md`, `graphql-schema-design.md` |
| 3. Contract | Spec file + cross-cutting decisions (auth, errors, paging, versioning) | `openapi-workflow.md`, `auth-patterns.md`, `error-and-pagination-patterns.md` |
| 4. Review | Completed `assets/api-design-checklist.md` + findings | `versioning-and-evolution.md` |

## Quick Start Guides

### Path 1: Design a New API

1. Copy `assets/api-brief-worksheet.md` into the project and fill it (or answer its questions interactively)
2. Pick the protocol from the Protocol Selection table above
3. Model resources with `references/rest-resource-modeling.md` (or SDL with `references/graphql-schema-design.md`)
4. Decide auth, versioning, pagination, and errors from the tables above — record each decision with rationale
5. Author the OpenAPI 3.1 spec per `references/openapi-workflow.md`
6. Self-review against `assets/api-design-checklist.md`; fix all critical findings before handing to implementation

### Path 2: Review an Existing API

1. Gather the contract: `openapi.yaml`, GraphQL SDL, proto files, or the router/route inventory
2. Walk `assets/api-design-checklist.md` section by section
3. Rank findings: **critical** (breaks consumers / security) / **major** (evolution hazard) / **minor** (consistency)
4. For each critical finding, propose a non-breaking remediation path using `references/versioning-and-evolution.md`

### Path 3: Plan an Evolution or Deprecation

1. Classify each proposed change: additive / deprecating / breaking (`references/versioning-and-evolution.md` has the classification table)
2. For breaking changes, design the additive bridge (new field/endpoint alongside old) and the deprecation timeline
3. Emit `Deprecation` + `Sunset` headers and changelog entries; define the migration guide outline
4. Gate with contract-diff tooling (oasdiff, buf breaking, GraphQL schema checks)

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Run any workflow as an agent** | `agent-playbook.claude-code.md` |
| **Model REST resources, URLs, methods, relationships** | `rest-resource-modeling.md` |
| **Design GraphQL schemas, mutations, federation** | `graphql-schema-design.md` |
| **Choose/execute a versioning strategy, deprecate safely** | `versioning-and-evolution.md` |
| **Define errors, pagination, rate limits, idempotency** | `error-and-pagination-patterns.md` |
| **Select auth: OAuth2/OIDC, API keys, mTLS, webhook signing** | `auth-patterns.md` |
| **Author, lint, mock an OpenAPI 3.1 spec** | `openapi-workflow.md` |
| **See a full design end-to-end** | `worked-example-payments-api.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-mcp-architect** — designs MCP server tool surfaces; use it instead of this skill when the "API" is an MCP server consumed by LLMs
- **trl-mcp-builder / trl-mcp-forge** — MCP ecosystem reference and implementation scaffolds; adjacent, not overlapping
- **trl-dba-db-designer-and-tuning** — designs the persistence schema your resources map onto; hand off the resource model
- **trl-technical-writer** — turns the finished OpenAPI spec into published reference docs and onboarding guides
- **trl-threat-modeler** — STRIDE review of the auth model and attack surface once the contract is drafted
- **trl-noizu-frameworks** — Elixir-side implementation context when the backend is a Noizu-stack Phoenix service

## Bundled Resources

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role definition and four executable workflows
- [rest-resource-modeling.md](references/rest-resource-modeling.md) — REST resource design: nouns, relationships, actions, bulk ops, worked example
- [graphql-schema-design.md](references/graphql-schema-design.md) — SDL design, mutations, connections, federation v2, worked example
- [versioning-and-evolution.md](references/versioning-and-evolution.md) — Change classification, strategy decision tree, deprecation mechanics, worked example
- [error-and-pagination-patterns.md](references/error-and-pagination-patterns.md) — RFC 9457 taxonomy, cursor pagination, rate limiting, idempotency, worked example
- [auth-patterns.md](references/auth-patterns.md) — OAuth 2.1/OIDC flows, API key lifecycle, mTLS, webhook signing, worked example
- [openapi-workflow.md](references/openapi-workflow.md) — Schema-first OpenAPI 3.1: structure, components, lint/mock/diff pipeline, worked example
- [worked-example-payments-api.md](references/worked-example-payments-api.md) — Full walkthrough: payments/billing API from brief to reviewed spec

### Assets
- [project-tracker.md](assets/project-tracker.md) — Phase/file progress tracker for a design engagement
- [api-design-checklist.md](assets/api-design-checklist.md) — Fillable review checklist (the Phase 4 gate)
- [api-brief-worksheet.md](assets/api-brief-worksheet.md) — Intake form capturing consumers, operations, and constraints
