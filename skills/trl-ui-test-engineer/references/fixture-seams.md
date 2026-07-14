# Fixture Seams — Tests Own Their Data

A fixture seam is a deliberate, gated backend surface that lets tests create accounts, seed entities, and reset state deterministically. Without seams, e2e tests share mutable state and every run inherits the wreckage of the last — the root cause of most "works locally, flaky on CI" suites.

## The Three Canonical Seams

| Seam | Purpose | Shape |
|------|---------|-------|
| `create-account` | Mint a user (with role/flags) + auth token in one call | POST, returns `{ user, token }` |
| `seed-entities` | Materialize a named scenario ("checkout-baseline") or explicit entity payload | POST, returns created ids/slugs |
| `reset-state` | Return the world owned by this test run to a known baseline | POST, scoped by run/namespace |

Delivery mechanisms — pick per backend:
- **Gated HTTP endpoints** (shown below) — works for any test runner, agents included
- **`cy.task`** calling backend management commands — when HTTP exposure is unacceptable even gated

## Gating Rules (Non-Negotiable)

1. **Env flag**: the seam app/router is only mounted when `TEST_SUPPORT_ENABLED=1`. Not a runtime check inside a always-mounted view — the routes must not exist otherwise.
2. **Shared secret**: every request carries `X-Test-Support-Key`; compared in constant time against `TEST_SUPPORT_KEY`.
3. **NEVER in prod.** Deployment config for production must not define either variable; a startup assertion refuses to boot if `TEST_SUPPORT_ENABLED=1` while `ENVIRONMENT=production`.
4. **Idempotency keys**: seed calls accept `Idempotency-Key`; replaying a seed (retried spec, agent re-run) returns the original result instead of duplicating data.

## Cleanup Ownership

**Seed-owned, not teardown-owned.** Each seed call tags what it creates (run id / namespace); the *next* run's `reset-state` (or `seed`'s implicit reset) clears the previous residue. `after()`/`afterEach()` hooks are best-effort courtesy only — they don't run when a test crashes mid-flow, the browser dies, or CI kills the job. A suite whose correctness depends on `after()` is a suite that fails after any failure.

```
correct:   before/seed guarantees clean state  →  test  →  (after: optional tidy)
incorrect: test  →  after MUST clean or the next run breaks
```

## Stub-vs-Live Policy

| Tier | Network | Data source |
|------|---------|-------------|
| Component tests | Everything stubbed with `cy.intercept` | Inline fixtures |
| E2e happy paths | Live backend | Fixture seams (`cy.seed`) |
| E2e error/edge paths | Live baseline + `cy.intercept` for the failing call | Seams + stubs |
| Prod/staging smoke | Live | Real data, read-mostly — seams are never enabled here |

Contract testing (Pact or schema-diff between the frontend's stub fixtures and the real API) is the disciplined way to keep component-tier stubs honest — worth adopting once the tiers above are stable; deferred here.

## Worked Example: Django `test_support` App

```python
# test_support/apps.py — only installed when gated
# settings.py:
#   if env.bool("TEST_SUPPORT_ENABLED", False):
#       assert env("ENVIRONMENT") != "production", "test_support must never ship to prod"
#       INSTALLED_APPS += ["test_support"]

# test_support/views.py
import secrets
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

def _gate(request):
    key = request.headers.get("X-Test-Support-Key", "")
    if not secrets.compare_digest(key, settings.TEST_SUPPORT_KEY):
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("bad test-support key")

@api_view(["POST"])
@permission_classes([AllowAny])
def create_account(request):
    _gate(request)
    profile = request.data.get("profile", "shopper")
    user = build_user(profile=profile, namespace=request.data["run_id"])
    token, _ = Token.objects.get_or_create(user=user)
    return Response({"email": user.email, "token": token.key}, status=201)

@api_view(["POST"])
@permission_classes([AllowAny])
def seed_entities(request):
    _gate(request)
    idem = request.headers.get("Idempotency-Key")
    if idem and (prior := SeedReceipt.objects.filter(key=idem).first()):
        return Response(prior.result, status=200)
    result = run_scenario(request.data["scenario"], namespace=request.data["run_id"])
    if idem:
        SeedReceipt.objects.create(key=idem, result=result)
    return Response(result, status=201)

@api_view(["POST"])
@permission_classes([AllowAny])
def reset_state(request):
    _gate(request)
    purge_namespace(request.data["run_id"])   # deletes only entities tagged with this run
    return Response({"reset": True})
```

```python
# test_support/urls.py — mounted under /__test__/ only when the app is installed
urlpatterns = [
    path("__test__/accounts/", views.create_account),
    path("__test__/seed/", views.seed_entities),
    path("__test__/reset/", views.reset_state),
]
```

## Cypress `seed()` Wrapper

```ts
// cypress/support/seams.ts
const RUN_ID = Cypress.env('runId') ?? `local-${Cypress.spec.name}`;

function seam(path: string, body: object, idem?: string) {
  return cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/__test__/${path}/`,
    headers: {
      'X-Test-Support-Key': Cypress.env('testSupportKey'),
      ...(idem && { 'Idempotency-Key': idem }),
    },
    body: { ...body, run_id: RUN_ID },
  });
}

Cypress.Commands.add('seed', (scenario: string) => {
  seam('reset', {});                                  // seed-owned cleanup: reset FIRST
  return seam('seed', { scenario }, `${RUN_ID}:${scenario}`).its('body');
});

Cypress.Commands.add('createAccount', (profile: string = 'shopper') =>
  seam('accounts', { profile }).its('body'),          // → { email, token }
);
```

```ts
// spec usage
beforeEach(() => {
  cy.seed('checkout-baseline').as('world');   // deterministic state, every run
});
```

The same seams serve agent exploration runs (`agentic-exploration.md`) — agents and specs share one seeding vocabulary, so what an agent explored is exactly what a spec will see.
