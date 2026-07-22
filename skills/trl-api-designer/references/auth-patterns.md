# Auth Patterns

Selecting and specifying authentication and authorization for an API contract: OAuth 2.1/OIDC flows, API key lifecycle, mTLS, webhook signing, scope design, and multi-tenant authorization. Ends with a worked example.

> Scope note: this file covers auth as a *contract design* decision. For adversarial review of the finished design, hand off to **trl-threat-modeler**.

## Selection Matrix

| Consumer | Pattern | Token/credential | Notes |
|----------|---------|------------------|-------|
| First-party SPA / mobile | OIDC Authorization Code **+ PKCE** | Short-lived JWT access token (5–15 min) + rotating refresh token | Never implicit flow (removed in OAuth 2.1); refresh tokens in httpOnly cookie (web) or secure storage (mobile) |
| Third-party apps acting for a user | OAuth 2.1 authorization code + consent | Scoped access token | Password grant is gone in 2.1 — never accept user passwords via partners |
| Partner/server backends | OAuth client credentials **or** API keys | `client_id`+`client_secret` → token, or long-lived key | Client credentials when you already run an authz server; API keys are fine and simpler when scoping is coarse |
| CLI / developer tooling | Device authorization grant | Same as above | The "enter this code at /activate" flow |
| Internal service-to-service | mTLS (mesh-issued) + workload identity | SPIFFE/SVID or mesh certs | Transport-level identity; pair with per-service authz policy |
| Machine consumers of webhooks (you calling them) | HMAC signature | Shared endpoint secret | See webhook signing below |

Decision heuristics:
- **Users involved → OAuth/OIDC. Machines only → keys, client credentials, or mTLS.**
- Don't build an authz server for two partners — API keys with good lifecycle discipline beat a half-implemented OAuth stack.
- JWTs for access tokens (stateless verification at the edge); opaque tokens when instant revocation matters more than verification cost.

## API Key Lifecycle (the underspecified 80% case)

| Concern | Rule |
|---------|------|
| Format | Prefixed + random: `nz_live_9f8K...` / `nz_test_...` — prefix enables secret scanning and env disambiguation |
| Storage (server) | Hash (SHA-256 is fine — keys are high-entropy); store prefix + last 4 in plaintext for display |
| Transmission | `Authorization: Bearer <key>` header — never query params (logs, referrers) |
| Rotation | Support ≥2 active keys per account so rotation is zero-downtime; document a rotation runbook |
| Scoping | Per-key scopes + optional IP allowlist; test-mode keys hit isolated data |
| Revocation | Immediate; emit an audit event |
| Leak response | Publish the regex (`nz_live_[A-Za-z0-9]{32}`) to secret-scanning programs (GitHub advanced security) |

## Token and Session Parameters

| Parameter | Default | Rationale |
|-----------|---------|-----------|
| Access token TTL | 5–15 min | Bounds the blast radius of a stolen token |
| Refresh token TTL | 14–30 days, **rotating** (one-time-use, reuse detection revokes the family) | Detects token theft |
| JWT contents | `sub`, `iss`, `aud`, `exp`, `iat`, `scope`, tenant/org claim | Keep small; no PII beyond an ID; `aud` must be your API, checked |
| Signing | Asymmetric (ES256/EdDSA) + JWKS endpoint with key rotation | Resource servers verify without a shared secret |
| Clock skew allowance | ≤ 60s | |

## Scope Design

Scopes are part of the public contract — design them with the resource model:

| Style | Example | Use |
|-------|---------|-----|
| `resource:action` | `payments:read`, `payments:write`, `refunds:write` | Default — maps 1:1 to the resource table in the design doc |
| Coarse role bundles | `admin`, `read_only` | Small partner APIs where granularity is theater |
| Fine-grained + hierarchical | `payments:read` implied by `payments:write` | Document the implication lattice explicitly |

Rules: every endpoint in the spec declares its required scope (OpenAPI `security` per operation); adding a scope requirement to an existing endpoint is a **breaking change**; new endpoints define scopes at birth.

## Multi-Tenant Authorization

AuthN says who; the contract must also pin **which tenant**:

| Decision | Options | Default |
|----------|---------|---------|
| Tenant binding | In token claim (`org_id`) vs path (`/orgs/{org_id}/...`) vs header | Token claim for single-org credentials; path when one credential legitimately spans orgs |
| Cross-tenant leakage guard | Every query filtered by tenant from the *credential*, never from a client-supplied body field | Non-negotiable — client-supplied tenant IDs are IDOR bait |
| Object-level checks | 404 (hide existence) vs 403 (admit existence) for foreign-tenant objects | 404 for tenant-scoped resources |

## mTLS (internal and high-assurance external)

| Aspect | Guidance |
|--------|----------|
| Internal mesh | Let the mesh (Istio/Linkerd) issue and rotate certs; the API contract just states "callers present mesh identity; service X allowed methods Y" |
| External mTLS (banking/health partners) | Certificate-bound access tokens (RFC 8705) — OAuth token usable only over the presenting cert's connection |
| Cost | Client cert distribution/rotation is heavy ops; only choose external mTLS when the compliance regime demands it |

## Webhook Signing (you → consumers)

```
X-Webhook-Signature: t=1752585600,v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
v1 = hex(hmac_sha256(endpoint_secret, "{t}.{raw_body}"))
```

Contract requirements to document for consumers: verify before parse; constant-time compare; reject `|now - t| > 300s`; per-endpoint secrets with rotation support (send `v1` under old and new secret during overlap); raw body (not re-serialized JSON) is the signed message.

## Worked Example: Auth for a Billing API

Consumers: (a) first-party Next.js dashboard, (b) ~30 partner backends, (c) internal Phoenix services, (d) partner webhook receivers.

| Consumer | Decision | Rationale |
|----------|----------|-----------|
| Dashboard | OIDC code + PKCE against the org IdP; 10-min ES256 JWTs, rotating refresh in httpOnly cookie | Users + browser; standard |
| Partners | API keys `nz_live_*` with scopes `invoices:read`, `payments:write`, etc.; 2 active keys/account | 30 machine consumers don't justify running client-credentials infra; scoping needs are coarse |
| Internal services | Mesh mTLS + `svc` claim in an internally-issued token | Already on Istio; contract lists allowed service→endpoint pairs |
| Webhooks | HMAC scheme above, per-endpoint secrets, 5-min skew window | |

Spec impact: `components.securitySchemes` defines `oidc` and `apiKey` (bearer); every operation lists required scopes; tenant comes from the credential (`org_id` claim / key ownership) — `POST /payments` body has **no** org field. Threat-model handoff noted for the refund path (highest-value abuse target).
