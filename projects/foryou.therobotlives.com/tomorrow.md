# foryou.therobotlives.com — Tomorrow (pick up here)

_Last worked: 2026-07-22 (session "foryou", coordinator = Loom). Branch: `develop` (shared multi-session checkout — NEVER git worktree; commit pathspec-limited, never bare `git commit`)._

## TL;DR prompt for next session

> Resume the foryou platform build-out. **First: review + commit the uncommitted B.1 (backend enrichment) and G (per-site listmonk repoint + provisioning manifest) work already in the working tree** (see "Uncommitted — review & commit first" below), verify each compiles/tsc-clean, then commit pathspec-limited per project and push `develop`. **Then: provision the foryou Lists on live** (run `projects/foryou.therobotlives.com/provisioning/` against the deployed management API) so the repointed site forms + noizu.com contact form actually land signups. **Then: deploy the repointed sites + noizu.com, run the listmonk backfill (Chunk G's BACKFILL.md), and finally Chunk H (decommission listmonk).** Read this file, `project-management/roadmap/README.md`, and `project-management/PRDs/DECISIONS.md` first. Memory: `foryou-list-domain-design`, `foryou-deploy-version-drift`, `monorepo-no-git-worktrees`.

---

## ✅ DONE + LIVE (deployed & verified this session)

- **M0** — cookie button removed from navbar (item 1); create-org UI for orgless users (item 2); `RequireAdmin`/`:admin` schema fix; CORS env allowlist; guarded `/app/admin` layout.
- **Chunk B (M1)** — Service/List/Attribute/Signup backend domain: changelogs `028-lists` + `029-signups`, `Foryou.Lists`/`Foryou.Signups`, full endpoint surface (public manifest+signup 202-no-leak, JWT PBAC reads, `Management.ListsController` reusing existing api-key surface, `/me/*`), reconcile-on-login, inquiries dual-write, TF `foryou_list` resource.
- **Chunks C+D+E (M3)** — signup widget (Shadow-DOM, 9.7KB), admin console (`/app/admin`), preference center (`/app/me`). All committed.
- **Chunk F (M4)** — noizu.com ContactModal: optional Company/Project-type/Budget/Timeline + repointed listmonk→foryou (item 4). Committed (`b5cab8b4749`). NOT yet live (needs noizu.com deploy + the `noizu-contact` List provisioned).
- **PM artifacts** — 8 personas, 100 stories, 22 screens, 22 components, M0–M5 roadmap, PRDs B–E + DECISIONS.md (D1–D17).
- **LIVE DEPLOY** — backend `v1.0.6` + frontend `v1.0.3` in `apps/foryou` (helm rev 13+). Liquibase `028/029` applied to the live DB via `liquibase-shell foryou update` (NOTE: the app boot does NOT run Liquibase — only Ecto legacy migrations; you MUST run liquibase-shell manually for new changelogs — see deploy notes). Verified live: site 200, public signup POST → 202, tables `lists`/`list_attributes`/`signups` present.

## ⚠️ Uncommitted — REVIEW & COMMIT FIRST (agents finished, not yet reviewed/committed)

These are in the working tree on `develop`, unreviewed. Review, verify, then commit pathspec-limited per project.

- **Chunk B.1 (backend endpoint enrichment)** — files: `app/backend/lib/foryou/signups.ex`, `.../controllers/{me_controller,admin_controller,lists_controller}.ex`, `.../router.ex`, new `.../workers/deletion_request_worker.ex`. Adds the endpoints the admin console + preference center degrade-gracefully around: serialize_signup service/list.settings enrichment, `/me` PATCH prefs / resubscribe / resume / export / deletion-request, admin overview / inquiries-read / server-side CSV / signup-detail. **Verify `mix compile` clean (toolchain: `export PATH="$HOME/.config/asdf/installs/erlang/29.0.2/bin:$HOME/.config/asdf/installs/elixir/1.20.1-otp-29/bin:$PATH"`), then commit + deploy a new backend image (monotonic tag → v1.0.7) + run liquibase-shell if any new changelog.** Once live, the admin/pref-center degraded surfaces light up automatically.
- **Chunk G (per-site listmonk repoint + provisioning)** — 8 site forms repointed listmonk→foryou (uncommitted): `therobotlives.com`, `codefre.sh` (×2: app + web), `aifighter.com`, `iotgo.io`, `jailbreakingsite.com`, `noizurpg.com`, `robots-unite.com`. Plus `projects/foryou.therobotlives.com/provisioning/` (README.md, provision-lists.sh, terraform/, BACKFILL.md). **Verify each site tsc-clean + no `listmonk.noizu.com` left, then commit per-project.** These forms 202 harmlessly until their foryou Lists are provisioned.

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
