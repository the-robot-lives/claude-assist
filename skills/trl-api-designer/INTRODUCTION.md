---
skill: trl-api-designer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-15
---

# API Designer — Introduction

Designs and evolves API contracts: REST resource models, GraphQL schemas, gRPC/protobuf services, and OpenAPI 3.1 schema-first workflows. Covers versioning, auth patterns, pagination, RFC 9457 error taxonomy, rate limiting, idempotency, webhooks, and backward-compatibility policy. For engineers designing new APIs or evolving existing ones — Elixir/Phoenix backends, Next.js frontends, and beyond. Produces design documents, OpenAPI specs, and review reports — it does not implement the backend service.

## Input Contract

```yaml
inputs:
  arguments:
    - name: brief
      type: freeform
      required: true
      description: "What API to design, review, or evolve — domain, consumers, constraints"
      example: "Design a payments API for our billing service; consumers are our Next.js dashboard and third-party partners"

  file_conventions:
    - pattern: "assets/api-brief-worksheet.md (copied into the project)"
      format: markdown
      description: "Optional structured intake — fill before invoking for a complete design pass"
      schema: "See assets/api-brief-worksheet.md"
      example: |
        ## Domain
        Payments and billing
        ## Consumers
        Internal dashboard, partner integrations
    - pattern: "openapi.{yaml,json} or *.graphql or *.proto"
      format: yaml | json | custom
      description: "Existing contract file, required for review/evolution workflows"
      schema: "OpenAPI 3.1 / GraphQL SDL / proto3"
      example: |
        openapi: 3.1.0
        info: { title: Payments API, version: 1.0.0 }

  context_expectations:
    - "None required for a new design; existing spec or route/schema files for reviews"
    - "Repo access helps ground designs in real handlers (Phoenix routers, Next.js API routes)"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "API design document"
      path: "docs/api/{api-name}-design.md (or user-specified location)"
      format: markdown
      description: "Resource model, endpoint table, auth, versioning, error taxonomy, decisions with rationale"
      example: |
        # Payments API Design
        ## Resources
        | Resource | Path | Methods |
    - name: "OpenAPI 3.1 specification"
      path: "openapi.yaml (or user-specified)"
      format: yaml
      description: "Complete contract: paths, components, security schemes, examples"
      example: |
        openapi: 3.1.0
        paths:
          /payments: { ... }
    - name: "API review report"
      path: "returned inline or docs/api/{api-name}-review.md"
      format: markdown
      description: "Findings against assets/api-design-checklist.md with severity and fixes"

  side_effects:
    - "None — all output is file-based or inline; never modifies application code"

  handoff:
    - skill: trl-dba-db-designer-and-tuning
      artifact: "API design document (resource model)"
      description: "Resource model informs persistence schema design"
    - skill: trl-technical-writer
      artifact: "OpenAPI 3.1 specification"
      description: "Spec feeds published API reference documentation"
    - skill: trl-threat-modeler
      artifact: "API design document (auth section)"
      description: "Auth and surface decisions feed a STRIDE review"
```

## Conventions

```yaml
conventions:
  naming:
    - "REST paths: plural kebab-case nouns (/payment-methods), no verbs in paths"
    - "OpenAPI operationIds: camelCase verb-first (listPayments, createRefund)"
    - "Design docs use kebab-case filenames"
  structure:
    - "Contract-first: the spec is authored and reviewed before implementation"
    - "One API (bounded context) per design document and spec file"
    - "Every error response follows RFC 9457 problem details"
  anti_patterns:
    - "Do not use this skill for MCP server design — that is trl-mcp-architect/trl-mcp-builder/trl-mcp-forge"
    - "Do not use it for database schema design — that is trl-dba-db-designer-and-tuning"
    - "Do not ask it to implement handlers/resolvers — it designs contracts, not services"
    - "Do not version by breaking silently — every breaking change goes through the evolution workflow"
  prerequisites:
    - "For review/evolution workflows: the existing contract (spec file or route inventory) must be reachable"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | Full decision tables and phased design process |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | When running a specific workflow |
| 4 (as needed) | `references/rest-resource-modeling.md` | Modeling REST resources and relationships |
| 4 (as needed) | `references/graphql-schema-design.md` | GraphQL SDL, federation, N+1 concerns |
| 4 (as needed) | `references/versioning-and-evolution.md` | Versioning strategy, deprecation policy |
| 4 (as needed) | `references/error-and-pagination-patterns.md` | RFC 9457 errors, cursor vs offset pagination |
| 4 (as needed) | `references/auth-patterns.md` | OAuth2/OIDC, API keys, mTLS selection |
| 4 (as needed) | `references/openapi-workflow.md` | Schema-first OpenAPI 3.1 authoring and linting |
| 5 (example) | `references/worked-example-payments-api.md` | End-to-end design walkthrough |

## Quick Examples

### New API design
`/trl-api-designer design a REST API for order fulfillment; consumers are our storefront and a partner webhook feed`

### Review an existing contract
`/trl-api-designer review openapi.yaml against the design checklist`

### Plan an evolution
`/trl-api-designer we need to split the customers resource into accounts and contacts without breaking v1 clients`
