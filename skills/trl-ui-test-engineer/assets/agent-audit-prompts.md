# Agent Audit Prompts

Prompt templates for the six-stage loop in `references/agentic-exploration.md`. Fill `{...}` placeholders. All runs target seeded non-prod environments only.

## Exploration Run (Stage 1)

```
You are exploring {app-url} to produce an interaction trace for the "{flow-name}" flow.

Setup (do this first, via HTTP — never through the UI):
1. POST {api-url}/__test__/reset/  with run_id={run-id} and header X-Test-Support-Key.
2. POST {api-url}/__test__/seed/   scenario={scenario}, run_id={run-id}, Idempotency-Key={run-id}:{scenario}.
3. POST {api-url}/__test__/accounts/ profile={profile}; store the token in localStorage
   as authToken before loading the app.

Rules:
- Navigate ONLY via elements carrying data-cy attributes; record every interaction as
  act/target/observed entries (target = the data-cy / data-cy-id / data-cy-for triple).
- After each action, record what observably changed: data-cy-value deltas,
  data-cy-flag-* transitions, route changes, and network calls (method + path).
- If you must interact with an element that has NO data-cy attributes, do so, but log
  it in a `gaps:` list with route, a human description, and how you located it.
- Read-only toward the app code; never touch production; stop at {terminal-condition}.

Output: cypress/flows/{flow-name}.yaml with keys: flow, seed, profile, entry, trace,
terminal, gaps.
```

## Attribute Audit Run (Stage 2)

```
You are auditing data-cy* schema compliance on: {route-list} of {app-url}.
Seed and authenticate exactly as in the exploration prompt (run_id={run-id}).

For every route, walk the rendered DOM and score against this contract:
1. Every interactive element (button, a, input, select, textarea, [role=button],
   clickable cards) carries data-cy with a kebab-case ROLE (function, not appearance).
2. Every repeated list/grid item carries data-cy-id that is business-stable —
   FLAG any value that looks like an array index (0,1,2...) or a render key.
3. Major page regions carry data-cy-scope.
4. Scalars a test would assert (counts, ratings, prices, totals) are mirrored in
   data-cy-value on the element that displays them.
5. Portaled/overlay UI (menus, modals, tooltips) is cross-linked: trigger has
   data-cy-id, portal content has matching data-cy-for.
6. Async regions expose data-cy-flag-* state (loading, open, hydrated) where a test
   would otherwise have to guess.

This audit is READ-ONLY. Do not modify anything; do not submit forms with side effects.

Output: cypress/audit/coverage-report.md with (a) per-route table: interactive-with-
data-cy fraction, stable-list-id fraction, regions-scoped fraction, overall %;
(b) ranked gap list — rank by which flows each gap blocks, HIGH/MED/LOW;
(c) non-compliant patterns with file hints if source is available (grep for the
visible text or component name).
```

## Gap PR Run (Stage 3)

```
Using cypress/audit/coverage-report.md, fix the top {n} ranked gaps in {repo}.

Rules:
- ADDITIONS ONLY of {...cyAttrs({...})} / {...cyFlag(...)} spreads (src/utils/cypress.ts).
  No behavior, styling, or structural changes. No spec changes in this PR.
- Roles: kebab-case, functional names. Ids: business-stable slugs/db ids from props —
  if no stable id exists in props, note it in the PR description instead of inventing one.
- PR title: "test-attrs: annotate {routes} (annotation-only)". Body links the audit report.
```

## Triage Run (Stage 6)

```
Spec {spec-path} test "{test-name}" failed on run {run-id} ({fail-rate} historically).
Artifacts: {screenshots/command-log/CI-timing links}.

1. Reproduce: same seed scenario, profile, and entry route; attempt 5 runs
   (cypress run, not open). Record the reproduction rate.
2. Classify as exactly one of:
   - race: intercept registered after action, .then()-based assertion, saved element
     reference, or action before data-cy-flag-hydrated=true
   - stale-session: cy.session restored but first authenticated request 401s
     (check for missing/weak validate callback)
   - seed-leak: entities present that this test's seed did not create (check run_id
     namespacing and any after()-dependent cleanup)
   - regression: fails deterministically under reproduction — the app is wrong
3. Fix in the CORRECT layer (selector→command, navigation→step, data→seed);
   regressions get a bug report, not a test patch. Verify with 5 consecutive greens.

Output: cypress/triage/{run-id}.md — Reproduced / Classification / Evidence /
Fix-or-Bug / Post-fix evidence.
```
