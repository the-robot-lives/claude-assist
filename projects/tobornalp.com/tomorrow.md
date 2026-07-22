# tomorrow.md — tobornalp build-out handoff

**Last session:** 2026-07-22 (tobor-sessions `395ad55a-41fe-4511-87cb-28e015efbc39`)
**Live version:** backend + frontend **v1.0.18** (helm rev 29), migrations 034–043 applied to prod.

---

## ▶ Resume prompt (paste this to kick the next session)

> Resume the tobornalp full-roadmap build-out. Chunks A + B + fixes are shipped **LIVE** (backend+frontend v1.0.18, prod migrations 034–043 applied, helm rev 29). **Next: chunk C** (capture / agents / prompts). Do it in this order:
> 1. **Platform prerequisite first** — land the `llm_models` / genai provider registry. The `genai` dep is declared but **unwired** and there's no `llm_models` table; every AI story (M3+) and WS-J US-076 in chunk C need it. This is WS-L/platform scope.
> 2. **PRD pipeline** — run `npl-prd-editor` for chunk C's 3 stories **before** any coding: **WS-B US-006** (quick-capture, Cmd+K), **WS-J US-076** (agent team dashboard — implements against `project-management/contracts/agent-runtime-contract.md`), **WS-K US-086** (prompt versioning). Stories are 5-bullet AC templates, NOT implementation-ready — PRDs are the gate.
> 3. **Implement** one agent per lane (disjoint dirs + migration blocks): WS-B `domains/inbox` + `app/[orgId]/inbox/**`, WS-J `domains/agents` + `app/[orgId]/agents/**`, WS-K `domains/prompts` + `app/[orgId]/prompts/**`. Physical changelog numbers continue **contiguously from 044** (assign per lane; the 100s/140s in the roadmap are logical, not physical). Lanes must NOT touch shared hotspots (`router.ex`, `db/changelog-master.yaml`, `mix.exs`, `package.json`, `org-nav.tsx`) — a WS-L integration pass wires those serially after.
> 4. **WS-L integration** — register changelogs in master, add routes to `router.ex`, add nav entries, reconcile `api.ts`. Apply the new changelogs to a test DB, run **full** `mix test test/therobotplans/` (the test alias now does ecto.create+liquibase.update+ecto.migrate), `npm run build`.
> 5. **Deploy** via the recipe below (publish cycle 2).
> Read `~/.claude/plans/flickering-yawning-corbato.md`, `project-management/roadmap/README.md`, and the memory `tobornalp-full-roadmap-execution` first. Register a tobor-sessions session before starting.

---

## Where we are (done this session)

- **M0 CLOSED.** Contracts delivered under `project-management/contracts/`: `agent-runtime-contract.md` (gates all AI stories M1→M5), `today-read-model.md` (+ `Today.Provider` behaviour shape), `adr-item-polymorphism.md`, `audit-matrix.md`. Frontend foundation: `@/components/ui` lib, `use-api` hook, loading/error/not-found conventions, 6 pages de-inlined to tokens, `proxy.ts` auth gate (Next 16 renamed middleware→proxy).
- **Chunk A (platform baseline) — LIVE.** Backend: items `rank`/`start_date`/`due_date`/`estimate` + `item_events` (best-effort capture w/ actor), `Items.update/3` actor threading, **OkrController org-authz security fix** (`with_org_objective/5`), fixed a latent mixed-keys bug that crashed every REST item PATCH. Frontend: on-brand UI lib + conventions.
- **Chunk B (3 verticals) — LIVE.** WS-A personal todos (due/tags/recurrence, materialize-on-complete, owner-private), WS-C projects + methodology provisioning (transactional, reuses `board_stages`), WS-I OKR hierarchy + rollup engine (3 strategies, cycle/depth trigger, `lower_better`/clamp correctness fix). Each lane wrote an inert `Today.Provider`. PRDs at `project-management/PRDs/US-{011,021,069}-*.md`.
- **Pre-existing fixes:** test alias now runs `ecto.migrate` (Oban/smart_token tables present on fresh DB), `router.ex` root-MCP aggregator alias fixed, `projects_mcp_test.exs` pins fixed — **full `mix test` runs (59 pass / 0 fail)**.

## What's next (chunks C–H)

| Chunk | Lanes / stories | Notes |
|---|---|---|
| **C — capture/agents/prompts** | WS-B US-006, WS-J US-076, WS-K US-086 | **Needs `llm_models`/genai registry first.** WS-J implements the agent-runtime contract. |
| D — ops verticals | WS-E US-041, WS-F US-048, WS-G US-056, WS-H US-064 | greenfield cicd/monitoring/docs/checklists |
| E — daily-use PM | WS-L US-001 (today dashboard aggregator), WS-C portfolio + **@dnd-kit kanban US-022**, WS-A habits/smartlists | the chunk that makes it daily-usable |
| F — M2 governance/ops | ~29 stories — **split into 2 cycles**; US-077 (perms) + US-044 (changelog svc) are load-bearing | WS-H US-065 transition-guard reaches across lanes — coordinate hook via WS-L ticket |
| G — M3 AI wave | 33 stories; US-078 audit log is the cross-lane spine | needs `llm_models` + agent audit |
| H — M4 enterprise + M5 release | portfolio/gantt/reports, US-100 capstone, a11y/perf/helm hardening | file the Diana billing epic (out of scope) |

## DEPLOY recipe (verified — use every chunk)

Prod deploys run **only from a human-user-backed main thread** (subagents are classifier-blocked: "no human user in transcript"). Permission rules are in `.claude/settings.local.json` (`deploy-service`/`liquibase-shell`/`helm-upgrade`).

1. `deploy-service tobornalp.com/{backend,frontend}` — builds+pushes via buildx (**registry-only**, no local `docker images` entry; bumps Infisical edge but does **NOT** bump `values.yaml` or helm-upgrade for tobornalp).
2. `docker manifest inspect ops.noizu.com/tobornalp.com/{backend,frontend}:v1.0.N` — confirm the pushed tag exists.
3. **Manually edit** `projects/tobornalp.com/helm/therobotplans/values.yaml` backend + frontend tags.
4. `helm-upgrade --include tobornalp --headless` — **`--headless` is required** (default prompts via `/dev/tty`, dies non-interactively). Both containers share ONE pod (`deploy/tobornalp-therobotplans`).
5. Migrations (apply **before** the backend rolls): `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home liquibase-shell therobotplans -- update <<< 'yes'` (env `JAVA_HOME` is stale 17.0.19).
6. Verify: `kubectl -n apps get pod -l app.kubernetes.io/instance=tobornalp` (Running, both images new) + smoke `https://tobornalp.com/api/v1/today` (401 ok, not 500) + `/` (200).

## Standing notes / gotchas

- **Git:** work is on `develop` (a background agent committed+pushed a 443-file "wip" mega-commit `b77b2d410b7` — accepted as-is per user; tobornalp WIP is captured). `feat/tobornalp-fleshout` branch exists but is 41 commits behind develop — ignore it, work on develop.
- **Coordination rules:** one agent per lane stays in its dirs + migration block = near-zero conflict. Physical changelog numbers are contiguous from 044 (assign as coordinator). Lanes report routes/changelog-filenames/deps; WS-L integration wires shared hotspots serially.
- **Mix cwd:** `projects/tobornalp.com/app/backend` (≠ NPL). Toolchain: `export PATH="$HOME/.config/asdf/shims:$PATH"`; Liquibase needs JDK 17.0.20 (`/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`).
- **Don't deploy half-built images** — each verified chunk ships as a unit.
- Plan file: `~/.claude/plans/flickering-yawning-corbato.md`. Memory: `tobornalp-full-roadmap-execution` (+ index in `MEMORY.md`).
