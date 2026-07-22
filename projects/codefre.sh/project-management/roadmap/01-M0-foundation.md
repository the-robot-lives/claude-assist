# M0 — Foundation & Contract Freeze

**Impl-plan stages:** 0, 0.5 · **Stories:** 4 · **Status:** in progress 🟡

## Mission

Make the platform buildable and the interfaces frozen. Execute the ~54 staged
migrations, stand up Oban, CI, Cypress scaffolding, outbound OTel, and the auth/invite +
API-token surfaces — then freeze the four contracts every later milestone consumes.
Nothing downstream starts until the contracts are versioned and merged.

## Entry criteria

None — this is the origin milestone. (Auth + invite-token system already implemented;
Accounts/Organizations contexts and AuthController exist.)

## Exit criteria

- All staged migrations executed against dev + CI databases; `mix test` green in CI.
- Oban running; Cypress scaffold with at least one passing smoke spec.
- Login, org creation, member invite, and API-token issue/revoke work end-to-end.
- The four contracts are frozen, versioned, and merged (see Lane B).

## Lane A — Platform foundations

**Zone / exclusive surfaces:** `app/backend/` platform plumbing (migrations, Oban config,
CI workflows, `accounts`, `auth`, `api_tokens` contexts), auth screens in
`app/frontend/`.

| Story | Title | Pri |
|---|---|---|
| US-039 | Create an organization | P0 |
| US-040 | Invite a user as a member of an organization | P0 |
| US-096 | Issue an API token for SDK / CLI use | P1 (forward-loaded — CLI login contract) |
| US-097 | Revoke or rotate an API token | P1 (forward-loaded) |

Also non-story foundation work per impl-plan Stage 0: run migrations, Oban, outbound
OTel, OpenAPI spex wiring, Cypress scaffold, CI, auth-UI fix, audit ingest.

## Lane B — Contract freeze (no stories)

**Zone / exclusive surfaces:** `docs/arch/` contract documents + generated schema
artifacts.

Freeze and version:
1. **OpenAPI spec** — the API surface all frontends, CLI, and SDKs consume.
2. **YAML script schema** — import/export format (US-007/US-008, CLI runs).
3. **Rubric DSL JSON-schema** — scoring configuration format.
4. **OTLP receiver contract** — inbound span shape for M6 ingestion and the M6 SDK
   OTel bridge.

## Cross-lane integration task

A CI run that: executes migrations from zero, boots the app, exercises
login → create org → invite → issue token via API against the frozen OpenAPI spec, and
validates the four contract documents against their schemas.
