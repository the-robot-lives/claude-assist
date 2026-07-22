# OpenAPI 3.1 Schema-First Workflow

Authoring an OpenAPI 3.1 contract before code exists, keeping it lint-clean, and preventing spec/implementation drift. Ends with a worked example fragment.

## Why 3.1 (not 3.0)

| 3.1 change | Design impact |
|------------|---------------|
| Schemas are full JSON Schema 2020-12 | `$defs`, `if/then`, `prefixItems`, proper `examples` arrays; no more `nullable:` — use type arrays: `type: [string, "null"]` |
| `webhooks` top-level section | Outbound event contracts live in the same spec as the API |
| `jsonSchemaDialect`, `$schema` support | Schemas can be shared verbatim with validation middleware |
| `license.identifier` (SPDX), `info.summary` | Metadata niceties |

Migration gotcha: 3.0's `nullable: true` and single `example` keyword are invalid/deprecated in 3.1 — lint rules catch these.

## Schema-First Pipeline

```
design doc ──▶ openapi.yaml ──▶ lint (spectral) ──▶ mock (prism) ──▶ consumer feedback
                    │                                                       │
                    ├──▶ diff gate (oasdiff) on every PR ◀──────────────────┘
                    ├──▶ server stubs / request validation middleware
                    ├──▶ client SDKs (openapi-generator / oapi-codegen / openapi-ts)
                    └──▶ published docs (redoc / scalar) ──▶ trl-technical-writer
```

| Stage | Tool (2026 defaults) | Gate |
|-------|----------------------|------|
| Lint | `spectral lint` with `spectral:oas` + org ruleset, or `redocly lint` | CI-blocking; exceptions documented inline with `# spectral-disable` + reason |
| Mock | `prism mock openapi.yaml` | Consumers integrate against the mock before the backend exists — this is the payoff of schema-first |
| Breaking-change diff | `oasdiff breaking base.yaml head.yaml` | CI-blocking unless PR carries an approved evolution plan |
| Drift prevention | Runtime request/response validation from the spec (Elixir: `open_api_spex`; Node: `express-openapi-validator`) | The spec validates production traffic — drift becomes a 500 in staging, not a support ticket |

Elixir/Phoenix note: `open_api_spex` supports spec-first (import) and code-first (annotate) — in schema-first flow, keep `openapi.yaml` canonical and validate the served spec against it in a test.

## File Organization

Single file until ~2k lines, then split by `$ref`:

```
api/
├── openapi.yaml            # info, servers, tags, security, paths ($ref'd)
├── paths/payments.yaml
└── components/
    ├── schemas/payment.yaml
    ├── parameters.yaml     # shared: cursor, limit, Idempotency-Key
    └── responses.yaml      # shared problem+json responses
```

Bundle for distribution: `redocly bundle openapi.yaml -o dist/openapi.yaml`. Keep `$ref`s one level deep; circular schema refs are legal but break half the codegen ecosystem — avoid.

## Authoring Rules

| Element | Rule |
|---------|------|
| `operationId` | Required, unique, camelCase verb-first (`listPayments`, `createRefund`) — it names generated client methods |
| Tags | One per resource, each with a `description`; every operation tagged exactly once |
| Parameters | Shared ones (`cursor`, `limit`) defined once in `components.parameters`, `$ref`'d everywhere |
| Responses | Every operation lists all realistic codes; error codes `$ref` shared `Problem` responses; never a bare `default` with no schema |
| Examples | ≥1 request and response example per operation (`examples:` with named entries) — examples power mocks and docs |
| Enums | Always paired with a description of the tolerant-reader rule for response enums |
| `readOnly`/`writeOnly` | Use them — one `Payment` schema serves both directions instead of `PaymentRequest`/`PaymentResponse` twins |
| Security | Global default + per-operation override; scopes listed per operation |

## Worked Example Fragment

```yaml
openapi: 3.1.0
info:
  title: Billing API
  version: 1.0.0
  summary: Payments, invoices, and refunds for the billing platform
servers:
  - url: https://api.example.com/v1
security:
  - apiKey: []
tags:
  - name: payments
    description: Charge lifecycle — create, fetch, list, refund

paths:
  /payments:
    post:
      operationId: createPayment
      tags: [payments]
      security: [{ apiKey: [payments:write] }]
      parameters:
        - $ref: '#/components/parameters/IdempotencyKey'
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/Payment' }
            examples:
              basic:
                value: { amount: 4000, currency: USD, customer_id: cus_31aB, source_id: pm_8dE2 }
      responses:
        '201':
          description: Payment created
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Payment' }
        '422': { $ref: '#/components/responses/ValidationProblem' }
        '429': { $ref: '#/components/responses/RateLimitProblem' }

components:
  securitySchemes:
    apiKey: { type: http, scheme: bearer, description: "Prefixed key nz_live_* / nz_test_*" }
  parameters:
    IdempotencyKey:
      name: Idempotency-Key
      in: header
      required: true
      schema: { type: string, format: uuid }
  schemas:
    Payment:
      type: object
      required: [amount, currency, customer_id, source_id]
      properties:
        id: { type: string, readOnly: true, examples: [pay_7Yq2] }
        amount: { type: integer, minimum: 50, description: Minor units }
        currency: { type: string, enum: [USD, EUR] }
        customer_id: { type: string }
        source_id: { type: string }
        status:
          type: string
          readOnly: true
          enum: [pending, succeeded, failed]
          description: Clients MUST tolerate unknown future values.
        failure_reason: { type: [string, "null"], readOnly: true }
    Problem:
      type: object
      required: [type, title, status]
      properties:
        type: { type: string, format: uri }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }
        request_id: { type: string }
  responses:
    ValidationProblem:
      description: Request failed validation (RFC 9457)
      content:
        application/problem+json:
          schema:
            allOf:
              - $ref: '#/components/schemas/Problem'
              - type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        pointer: { type: string }
                        code: { type: string }
                        message: { type: string }
    RateLimitProblem:
      description: Rate limited (RFC 9457)
      headers:
        Retry-After: { schema: { type: integer } }
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }

webhooks:
  payment.succeeded:
    post:
      operationId: onPaymentSucceeded
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                id: { type: string, examples: [evt_2mQ8] }
                type: { const: payment.succeeded }
                data: { $ref: '#/components/schemas/Payment' }
      responses:
        '200': { description: Acknowledged }
```

Points demonstrated: 3.1 nullability (`type: [string, "null"]`), `readOnly` single-schema pattern, shared problem responses, tolerant-reader enum note, `webhooks` section, idempotency header as a shared parameter.

> Full spec in context: `worked-example-payments-api.md`.
