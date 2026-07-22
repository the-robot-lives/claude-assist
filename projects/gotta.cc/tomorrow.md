# gotta.cc — Tomorrow (pick up here)

_Handoff written 2026-07-22 (session `96934223-e372-463d-955b-985994ca9a34`). Today shipped the submission/moderation feature + native-auth fix and drove a first-time prod deploy. Deploy was ~90% through when we wrapped._

---

## ⏩ Paste-me prompt to resume

> Resume the gotta.cc roadmap. First **verify the prod deploy finished**: confirm the frontend image pushed, `kubectl -n apps rollout restart deploy/gotta-cc`, wait for rollout, then smoke `https://gotta.cc/` (must render the browse/search product, NOT the waitlist page) + a real register→submit round-trip against prod. Then do **P2-MERGE**: review `app/.design/curation/sites-external-graded.yaml` and seed the insert-ready sites into the prod `gotta_cc` DB (decide publish-now vs route-through-moderation first). Read the memory notes `gotta-cc-project-and-conventions`, `gotta-cc-implementation-gotchas`, `gotta-cc-submission-rubric-plan` before starting. Register a tobor work session first per CLAUDE.md.

---

## Where things stand

**Committed** (`develop`, SHA `02166702c76`): P2-SUBMIT backend (026 changelog `directory_submissions` + `directory_site_claims`, submissions/claims/moderation controllers + 9 routes, config-flagged open self-registration) + the native-auth 500 fix (entity `create/3` overrides were routing built structs through `Enum.map`) + submit/auth frontend (`/login /register /submit /my-submissions /claim/[slug] /moderation`, `session.ts`). Frontend `npm run build` green; backend HTTP smoke green (register 201 / login 200 / submission 201).

**Prod deploy — nearly done (finish it first):**
- ✅ DB **migrated** (first-time full 68-changeset Liquibase load) + **seeded** on **app-timescaledb** (`app-timescaledb.apps.svc.cluster.local`, DB `gotta_cc`). This is the chosen home DB — `values.yaml database.host` and the `GOTTA_CC_DATABASE_URL` secret are aligned to it.
- ✅ **Backend image** built + pushed (`ops.noizu.com/gotta.cc/backend:v1.0.edge`, digest `sha256:63012f6a…`).
- ✅ Config fix committed to `.infra-config.yaml` (uncommitted): frontend `NEXT_PUBLIC_API_URL` `api.gotta.cc → https://gotta.cc` (same-origin; ingress routes `gotta.cc/api → backend:4000`).
- ✅ **Frontend image** built + pushed — multi-arch manifest is up at `ops.noizu.com/gotta.cc/frontend:v1.0.edge` (fresh digest `sha256:08ea6ae6…`). ⚠️ The build wrapper exited 1 on "1/3 tags pushed": two auxiliary immutable tags (git-sha, timestamp) failed on **transient** buildkit `ref layer locked … Unavailable` errors (registry was saturated — ~12 apps pushing `v1.0.edge` at once). `:v1.0.edge` (the tag the chart pulls) DID push, so the rollout is fine. Optional: re-run `docker-build gotta.cc/frontend --push` to backfill the immutable tags. Sanity-check the digest is current before rolling: `docker buildx imagetools inspect ops.noizu.com/gotta.cc/frontend:v1.0.edge`.
- ⛔ **NOT yet done:** `rollout restart` + live smoke. (Both images are pushed; this is genuinely the only remaining step.) The chart pins the rolling `:v1.0.edge` tag, so a plain `helm upgrade` sees "no change" — you MUST `kubectl -n apps rollout restart deploy/gotta-cc` to pull the new images. `gotta-cc` is a **single deploy, two containers** (backend + frontend) in ns `apps`.

**Finish-the-deploy commands:**
```bash
export KUBECONFIG=~/.kube/noizu/config INFRA_ROOT=/Users/keithbrings/Work/Space/Infra/Noizu
# 1. confirm frontend pushed
docker buildx imagetools inspect ops.noizu.com/gotta.cc/frontend:v1.0.edge --format 'digest={{.Manifest.Digest}}'
# 2. roll the deploy (rolling tag ⇒ restart, not upgrade)
kubectl -n apps rollout restart deploy/gotta-cc
kubectl -n apps rollout status  deploy/gotta-cc --timeout=180s
# 3. smoke
curl -sS https://gotta.cc/api/v1/directory/categories        # 6 categories
curl -sS 'https://gotta.cc/api/v1/directory/sites?limit=3'
# register→submit round-trip (clean up the smoke rows after), then:
# open https://gotta.cc/  → must be the product (search + live category tiles), NOT "Join the Waitlist"
```
If `gotta.cc/` still shows the waitlist page after rollout, the frontend image didn't update — recheck the pushed digest / imagePullPolicy.

---

## Next work, in order

### 1. Finish + verify the deploy (above). This is the only thing blocking "it's live."

### 2. P2-MERGE — populate the directory with the mined candidates
- 85 external candidates were mined (`app/.design/curation/sites-external-candidates.yaml`) and **rubric-graded** into three slices + a consolidated `app/.design/curation/sites-external-graded.yaml` (the merge tasker was finishing at wrap-up — confirm it wrote; else merge the three `sites-external-graded-*.yaml` files: 65 PASS + 18 SOFT_FLAG = ~83 insert-ready, 2 REJECT).
- **DECISION NEEDED before inserting to prod:** publish the ~83 straight in (they're LLM-rubric-graded, which was the chosen gate), OR load them as `draft` / through the new **moderation queue** for an editorial pass (the rubric doc says an editor confirms before publish, and grading had 2 fetch-blocked misfires). Recommend: seed the high-confidence PASS (overall ≥ 85) as published, route the rest through `/moderation`.
- **Insert mechanism:** mirror the existing curated-site seeding — the 129 launch sites came from `sites-human-web.yaml` via `priv/repo/seeds/directory/002-sites.exs`. Convert the graded set to the same seed shape and run against prod `gotta_cc` (app-timescaledb), OR bulk-approve via the moderation API.
- **Re-source manually** (graders flagged; don't auto-insert as-is): `rachelbythebay.com` (WAF-blocked, false REJECT — canonical live blog, re-fetch in a browser), `paulsellers.com` (403 WAF, provisional score), `auntiepixelante.com` (genuinely parked — drop unless Anna Anthropy's writing relocated).

### 3. Commit the curation artifacts
The graded YAMLs (`sites-external-candidates.yaml`, `sites-external-graded*.yaml`) and the `.infra-config.yaml` API-URL fix are uncommitted. Commit once the insert approach is decided.

### 4. Deferred fixes
- **seed_helper changelog 002** creates a wrong-named table (`seed_helper_records`) — real table is `seed_helper_seeds` (+`seed_helper_handles`); patched ad-hoc on dev, add a corrective changelog so a from-scratch `make migrate` works. (See `gotta-cc-implementation-gotchas`.)
- **Waitlist form:** today's deploy agent tried to repoint signups from listmonk → an **unprovisioned foryou list** (`gotta-cc-waitlist`) and I reverted it. If migrating gotta.cc's waitlist onto the foryou signup service is actually wanted, provision the foryou List first (`projects/foryou.therobotlives.com/provisioning/`), then re-apply.

### 5. Broader (worth a ticket)
The native-auth 500 root cause (context `create/3` overrides iterating a built entity struct via `Enum.map`, plus a missing `email` and an unwrapped `{:ok, ref}` in session minting) means **native register/login never worked at runtime in the start-app scaffold**. The same bug very likely affects the other start-app apps (**foryou, tobornalp, codefre.sh, therobotmakes**) — they run SSO-only so it's been masked. Audit + fix across them, or fix upstream in the scaffold.

---

## Key facts / gotchas
- **Home DB = app-timescaledb** (`app-timescaledb.apps`, DB `gotta_cc`). Both gotta_cc instances were schema-empty before today; platform-timescaledb (via `shared-postgres.data-ns`) is NOT the target.
- Changelogs live in `app/backend/db/changelog/` (master `db.changelog-master.yaml`), NOT the stale `priv/repo/migrations` path in `.infra-config.yaml`.
- Deploy target: images `gotta.cc/backend` + `gotta.cc/frontend`; release `gotta-cc`; ns `apps`; single deploy / two containers; rolling `:v1.0.edge` tag ⇒ **rollout restart** to pull.
- Ingress: `gotta.cc/{api,health,auth,sso} → backend:4000`, `/ → frontend`. Frontend calls same-origin `https://gotta.cc`.
- seed gotchas: seed_helper 0.1.1 needs `seed {"name","1"}` tuples + `seed_helper_seeds`/`_handles` tables; run seeds via one-off container / host `mix run`, never `docker exec` into a running pod (`:eaddrinuse`).
- Scoring rubric: `app/docs/scoring-rubric.md` (5 dims: Originality 30 / Human Authorship 25 / Depth 20 / Freshness 15 / Design 10; anti-slop gate; LLM-grading prompt).
