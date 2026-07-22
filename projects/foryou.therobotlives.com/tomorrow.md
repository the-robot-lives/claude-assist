# foryou.therobotlives.com — Tomorrow (pick up here)

_Last worked: 2026-07-22 (session "foryou", coordinator = Loom). Branch: `develop` (shared multi-session checkout — NEVER git worktree; commit pathspec-limited, never bare `git commit`)._

## TL;DR prompt for next session

> Resume the foryou platform build-out. Everything through Chunk G is **committed + pushed** on `develop`; backend `v1.0.6` + frontend `v1.0.3` are **live**. **First: deploy the committed B.1 backend enrichment** (new backend image, monotonic tag → v1.0.7, `helm-upgrade --headless --force`; no new changelog so no liquibase-shell needed) — this lights up the admin console + preference center's degraded surfaces. **Then: provision the foryou Lists on live** (run `projects/foryou.therobotlives.com/provisioning/` against the deployed management API — needs a `FORYOU_API_KEY` + a `FORYOU_PROJECT_ID`; NOTE the owning Project must pre-exist, there's no `foryou_project` TF resource — create/seed one first) so the repointed site forms + noizu.com contact actually land signups. **Then: deploy the repointed sites + noizu.com** (each its own image/chart). **Then: run the listmonk backfill** (`provisioning/BACKFILL.md`). **Finally: Chunk H (decommission listmonk).** Read this file, `project-management/roadmap/README.md`, `project-management/PRDs/DECISIONS.md`. Memory: `foryou-list-domain-design`, `foryou-deploy-version-drift`, `monorepo-no-git-worktrees`.

---

## ✅ DONE + LIVE (deployed & verified this session)

- **M0** — cookie button removed from navbar (item 1); create-org UI for orgless users (item 2); `RequireAdmin`/`:admin` schema fix; CORS env allowlist; guarded `/app/admin` layout.
- **Chunk B (M1)** — Service/List/Attribute/Signup backend domain: changelogs `028-lists` + `029-signups`, `Foryou.Lists`/`Foryou.Signups`, full endpoint surface (public manifest+signup 202-no-leak, JWT PBAC reads, `Management.ListsController` reusing existing api-key surface, `/me/*`), reconcile-on-login, inquiries dual-write, TF `foryou_list` resource.
- **Chunks C+D+E (M3)** — signup widget (Shadow-DOM, 9.7KB), admin console (`/app/admin`), preference center (`/app/me`). All committed.
- **Chunk F (M4)** — noizu.com ContactModal: optional Company/Project-type/Budget/Timeline + repointed listmonk→foryou (item 4). Committed (`b5cab8b4749`). NOT yet live (needs noizu.com deploy + the `noizu-contact` List provisioned).
- **PM artifacts** — 8 personas, 100 stories, 22 screens, 22 components, M0–M5 roadmap, PRDs B–E + DECISIONS.md (D1–D17).
- **LIVE DEPLOY** — backend `v1.0.6` + frontend `v1.0.3` in `apps/foryou` (helm rev 13+). Liquibase `028/029` applied to the live DB via `liquibase-shell foryou update` (NOTE: the app boot does NOT run Liquibase — only Ecto legacy migrations; you MUST run liquibase-shell manually for new changelogs — see deploy notes). Verified live: site 200, public signup POST → 202, tables `lists`/`list_attributes`/`signups` present.

## ✅ Also committed this session (built + committed, NOT yet deployed)

- **Chunk B.1 (backend endpoint enrichment)** — `signups.ex`, `me_controller`, `admin_controller`, `lists_controller`, `router.ex`, new `deletion_request_worker.ex`. serialize_signup service{}/list.settings, `/me` PATCH/resubscribe/resume/export/deletion, admin overview/inquiries/CSV/signup-detail, lists index opt_in_mode+attribute_count, signups index attributes[]+q. `mix compile` clean; no migration. **NOT deployed** — needs a new backend image (→ v1.0.7). Once live, the admin/pref-center degraded surfaces light up.
- **Chunk G (per-site repoint + provisioning)** — 9 site forms repointed listmonk→foryou (committed): therobotlives.com, codefre.sh (×2), aifighter.com, iotgo.io, jailbreakingsite.com, noizurpg.com, robots-unite.com. Plus `provisioning/` (README, provision-lists.sh, terraform/lists.tf, BACKFILL.md). Forms 202 harmlessly until their foryou Lists are provisioned + the sites deployed.
- **Chunk F body-shape FIX** — noizu.com ContactModal was sending top-level `email`/`name`, which the public endpoint DROPS (it reads them from inside `values`). Fixed: email+name now inside `values`. **Same gotcha for anyone building a foryou signup client: put email + all attributes INSIDE `values`, keyed by slug — top-level fields are ignored (and the 202 no-leak hides the loss).**

## ▶️ NEXT (in order)

1. **Commit B.1 + G** (above). Redeploy foryou backend (B.1) → v1.0.7.
2. **Provision the foryou Lists on LIVE** — run `provisioning/` (management API key needed; backend is deployed). Lists: one per site (`*-waitlist`) + `noizu-contact` (attributes: company:string, project_type:select, budget_range:select, timeline:select). Without this, every repointed form + noizu.com contact just 202-drops. **This is the gate for items 3 & 4 to actually work.**
3. **Deploy the repointed sites + noizu.com** (each is its own image/chart — `deploy-service <domain>/frontend`; watch for the same version-drift, use monotonic tags + `helm-upgrade --headless --force`).
4. **Backfill listmonk subscribers → foryou** — follow `provisioning/BACKFILL.md`: export each listmonk list, `POST /api/v1/management/lists/:id/signups/import` (Oban, dedupe, never overwrites unsubscribed, no opt-in emails). **Grep each site's real list UUID (D8 — the old recon table is WRONG).**
5. **Chunk H — decommission listmonk** (only after ALL sites cut over + backfilled + verified): remove `terraform/kubernetes/platform/marketing/listmonk.tf` + its TimescaleDB db/role + DNS. Retain a final export/backup first.

## Deploy gotchas (learned the hard way — see memory `foryou-deploy-version-drift`)

- **Liquibase does NOT run on app boot.** The migrate-job/`Foryou.Release.migrate()` is Ecto-only (legacy oban/smart_token). New changelogs (028/029/…) must be applied manually: `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home; echo yes | liquibase-shell foryou update` (preview with `liquibase-shell foryou status`).
- **deploy-service version drift**: its auto-counter minted a tag BELOW live (v1.0.4 < live v1.0.5), so the bump/helm step self-skipped (silent half-deploy). Fix: re-tag monotonic via `buildx imagetools create`, edit values.yaml, `helm-upgrade --include foryou --headless --force`. Always use `--headless` (non-interactive; the wrapper reads `/dev/tty` otherwise). Verify `helm status foryou -n apps` REVISION advanced + pod age reset + live image tag.
- **Live = single Deployment `foryou-start-app`** in ns `apps`, 2 containers (`backend`+`frontend`). Not per-service deployments.

## Deploy-time config still needed for full functionality

- `CORS_ORIGINS` (portfolio domains) — else the CORS plug falls back to reflect-any (works but permissive).
- `FORYOU_DEFAULT_INQUIRY_LIST_ID` (D16) — after provisioning the default inquiry list; until set, the inquiry dual-write is a safe no-op.
- optional `:public_base_url` for confirm/unsub email links (defaults to Endpoint.url()).

## Key references
- Roadmap authority: `project-management/roadmap/README.md`
- Decisions: `project-management/PRDs/DECISIONS.md` (D1–D17)
- Plan: `~/.claude/plans/resilient-beaming-wozniak.md`
- tobor-sessions: `c34851fd-3df1-44b2-8a38-7c4a38b602be`
- Memory: `foryou-list-domain-design`, `foryou-deploy-version-drift`, `monorepo-no-git-worktrees`
