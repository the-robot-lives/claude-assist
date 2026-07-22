# API Brief Worksheet

Intake form for Phase 1 of the design process. Fill before (or during) `/trl-api-designer` invocation — unanswered items become the designer's first questions. Terse answers are fine; "unknown" is a valid answer that gets flagged, invented answers are not.

## 1. Domain

- **One-sentence purpose** (what business capability does this API expose?):
- **Bounded context** (what is explicitly OUT of scope for this API?):
- **Existing related APIs** (that this must feel consistent with):

## 2. Consumers

| Consumer | Type (1st-party web/mobile, partner backend, internal service, public) | Trust level | Est. call volume | Network quality |
|----------|------------------------------------------------------------------------|-------------|------------------|-----------------|
| | | | | |
| | | | | |

- **Who is the *second* consumer** (the one you're not building for yet)?
- **Can you identify and contact every consumer** (needed for deprecation)? yes / no

## 3. Operations

List every operation consumers need, in their words (not endpoint syntax):

| # | Operation (verb phrase) | Consumer(s) | Read/Write | Sync or can be async? |
|---|-------------------------|-------------|------------|----------------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

- **Which operations involve money, irreversible effects, or external side effects?** (these get idempotency + extra review):
- **What state changes do consumers need to be *notified* about** (webhook/event candidates)?

## 4. Data Sensitivity and Compliance

- **Sensitive data classes touched** (PII, payment, health, none):
- **Regulatory constraints** (PCI, GDPR, HIPAA, SOC2, audit retention):
- **Multi-tenant?** yes / no — if yes, tenant boundary:

## 5. Non-Functional Constraints

| Constraint | Requirement |
|------------|-------------|
| Latency expectations (p95) | |
| Expected list sizes (largest collection, growth rate) | |
| Availability target | |
| Burst/abuse concerns | |

## 6. Compatibility and Lifecycle

- **Existing clients that must keep working** (versions, platforms):
- **Public at launch, or internal-first?**
- **Expected rate of change** (stable domain vs actively evolving):
- **Who approves breaking changes?**

## 7. Stack Context (grounds the design, doesn't drive it)

- **Backend** (e.g. Elixir/Phoenix, Node):
- **Frontend(s)** (e.g. Next.js):
- **Existing auth infrastructure** (IdP, OAuth server, API gateway, service mesh):
- **Existing conventions to inherit** (error format, ID scheme, casing):

## 8. Success Criteria

- **This design is done when** (e.g. "spec reviewed, mock served, dashboard team integrated against it"):
- **Known open questions the designer should resolve**:
