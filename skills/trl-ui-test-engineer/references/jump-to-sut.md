# Jump to SUT — Sessions, Programmatic Login, Deep Links

Every second a spec spends *getting to* the thing under test is a second multiplied by every spec, every run. The pattern: seed → session → deep-link → test. Never re-earn state through the UI that some other spec already proved the UI can produce.

## cy.session Semantics

| Aspect | Rule |
|--------|------|
| Cache scope | Per-spec-file by default; `cacheAcrossSpecs: true` extends to the whole run — set it **deliberately** (shared sessions mean shared token lifetime across specs) |
| Setup | ALWAYS programmatic (API login). The login *form* gets its own dedicated spec; every other spec uses the API |
| `validate` | **REQUIRED, always.** Stale restored sessions are the #1 silent flake: token expired or user deleted server-side, session restores "successfully," first authenticated request 401s, and the failure surfaces as an unrelated element-not-found three commands later |
| `testIsolation` | Stays **ON**. Isolation clears page/state between tests; `cy.session` exists precisely so isolation stays cheap. Turning isolation off to "keep login" reintroduces ordered-test coupling |

## Programmatic Login (DRF Token Pattern)

Target backend shape: `POST /api/auth/login/` returns `{ token }`; the app stores it in `localStorage` and sends `Authorization: Token <token>` on API calls.

```ts
// cypress/support/auth.ts
type Profile = 'returning-shopper' | 'new-shopper' | 'admin';

const tokens = new Map<string, string>(); // module cache so validate() can reach the token

Cypress.Commands.add('loginAs', (profile: Profile) => {
  cy.session(
    ['auth', profile],
    () => {
      // 1. account from the fixture seam (never a hardcoded shared user)
      cy.createAccount(profile).then(({ email, token }) => {
        tokens.set(profile, token);
        // 2. bind the token to the app origin — localStorage is per-origin,
        //    so one visit is needed for the session snapshot to capture it
        cy.visit('/', {
          onBeforeLoad(win) {
            win.localStorage.setItem('authToken', token);
          },
        });
      });
    },
    {
      cacheAcrossSpecs: true, // deliberate: profile accounts are run-scoped, safe to share
      validate() {
        // cheap server-side truth check — catches expired/revoked tokens on restore
        cy.request({
          url: `${Cypress.env('apiUrl')}/api/users/me/`,
          headers: { Authorization: `Token ${tokens.get(profile)}` },
          failOnStatusCode: false,
        })
          .its('status')
          .should('eq', 200);
      },
    },
  );
});
```

Notes:
- `validate` failing causes Cypress to **re-run setup** — self-healing instead of silent flake.
- The token cache is module-level because `validate` runs on a blank page where the app's `localStorage` isn't yet readable; keep it keyed by profile, never a single global.
- If the app reads the token at boot only, deep-link visits after `loginAs` are already authenticated; if it reads per-request, nothing more is needed.

## The Timing Math

Form login click-through (visit `/login`, type email, type password, submit, wait for redirect, wait for hydration): **~12s** per test on a typical CI runner.

| Suite | Form login | `cy.session` + API |
|-------|-----------|--------------------|
| 1 test | ~12s | ~1.5s (first), ~0.3s (restore) |
| 80 authenticated tests | ~16 min of pure login | ~1.5s × profiles + 80 × 0.3s ≈ **30s** |

That is minutes of CI per run and — more importantly — 80 chances for the login UI to flake removed from specs that aren't about login.

## Deep-Link Entry

Specs enter at the closest routable URL to the behavior under test:

```ts
cy.seed('checkout-baseline');
cy.loginAs('returning-shopper');
cy.visit('/checkout');          // NOT: visit home → click nav → click cart → click checkout
```

Navigation *to* checkout is one spec's subject; for every other spec it's overhead. Requirements: routes are deep-linkable (fix the app if not — that's a product bug too) and the seed puts the world in a state where the deep link is valid (cart already populated).

## Account-Setup Hook Composition

Compose the standard preamble once:

```ts
// cypress/support/hooks.ts
export function withWorld(scenario: string, profile: Profile, path: string) {
  beforeEach(() => {
    cy.seed(scenario);
    cy.loginAs(profile);
    cy.visit(path);
    cy.get('[data-cy-flag-hydrated="true"]', { timeout: 10_000 }); // SSR guard, see network-and-antiflake.md
  });
}
```

```ts
describe('checkout', () => {
  withWorld('checkout-baseline', 'returning-shopper', '/checkout');
  it('pays with a saved card', () => { /* pure flow, zero preamble */ });
});
```

## OAuth Stance (Google et al.)

**Never automate the provider's UI.** It's not your code, it bot-detects, it A/B tests, and it will ban your CI IPs. Policy:

1. **All authenticated specs** use the programmatic token path above — the app doesn't care how the token was minted.
2. **At most one stubbed OAuth smoke test**: `cy.intercept` the app's own `/api/auth/google/` callback exchange, click the app-side "Sign in with Google" button, assert the app handles the stubbed success/failure payloads correctly. This tests *your* integration seam, which is the only part you own.
3. Real-provider verification is a manual/monitored concern (staging canary), not a per-PR spec.
