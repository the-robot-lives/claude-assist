# The Robot Learns — cutover COMPLETE (2026-07-23)

## Post-cutover session additions (same day)

Live now: backend v1.0.6 / frontend v1.0.8.

### Learning content model (changelog 028, be v1.0.6 / fe v1.0.8)

Cloud app = system of record (Keith's correction; see memory trl-product-model-cloud-is-system-of-record).
- 7 tables: lesson_plans, wiki_pages (slug auto, unique per project), quizzes, quiz_questions, reference_entries, decks, deck_cards. FK-cascaded to projects; child types validated through parent.
- Generic API (also the CLI/MCP PUSH surface): `/api/v1/organizations/:org_id/projects/:project_id/content/:content_type` — GET (list; `?parent_id=` for quiz-questions/deck-cards), POST `{item:{...}}`, PATCH `/:id`, DELETE `/:id`. Bearer JWT; PBAC project:view / project:update; created_by stamped. Types: lesson-plans, wiki-pages, quizzes, quiz-questions, references, decks, deck-cards.
- Frontend: wizard (3-step: basics/modules/review) at /app/[orgId]/projects/new; project workspace at /app/[orgId]/projects/[projectId] reads/writes real tables; settings jsonb now only stores module-enabled flags. Buttons restyled w/ TRL accent (#d85a24); dark-mode-legible outline buttons.
- Smoke-verified all types incl. parent-scoped question/card, 404 unknown type, 401 unauthed.

### Valkey incident + repair (same session)

app-valkey pod restart dropped the live-only `therobotlearns` ACL user → backend crash-loop (Redix WRONGPASS → app exit). Fixes:
- Immediate: `provision-db therobotlearns --redis-only` re-created the user.
- Durable: added therobotlearns to `acl_users` in terraform/kubernetes/apps/init/main.tf; `terragrunt apply -target=module.app_valkey` (full-stack plan has unrelated drift incl. helm_release churn + a foryou_site create — do NOT apply untargeted).
- Found + repaired REDACTED-MARKER contamination in Infisical /apps/valkey: THEROBOTLEARNS/AIFIGHTER/JAILBREAKING_VALKEY_PASSWORD all held the literal `🔒 **redacted**` string (past non-override populate); repopulated with real values (dc primary, k8s-secret fallback). aifighter/jailbreaking ACL users were broken this whole time.
- Gotcha: `dc get auto <key>` empty for apps_valkey_password (auto-layer CLI drift; value only lives in Infisical/k8s).

- OIDC round-trip CLOSED — Keith logged in end-to-end. Fixes along the way: SSO_DOMAINS
  default-closed policy (noizu.com + therobotlives.com allowed w/ auto-approve), missing
  auth_providers OIDC row (SSO path now upserts like register does), Chart helper block
  for SSO_DOMAINS ported.
- Scaffold branding removed (navbar/title), navbar Cookie Settings button dropped,
  consent storage keys renamed trl.*.
- Registration completion UX: invite field only for pending users, success toast,
  navigateTo helper fixes silent absolute-URL router.push no-op (6 call sites).
- Personal orgs: changelog 027 (organizations.personal flag), ensure_personal_org
  idempotent on register/SSO/completion; org listings expose the flag.
- REAL DASHBOARD (replaces placeholder at app/[orgId]): projects grid w/ create/archive/
  restore (new api.ts project fns against the already-implemented PBAC ProjectController),
  team snapshot, quick links, honest "learning data lives in local CLI workspace" callout.
  Learning widgets from screens 10/18 deliberately omitted — no backend tables yet.
- Backend bug fixed: Projects.list_for_user raw SQL passed string uuids (Postgrex
  EncodeError 500) — now dumps params / loads uuid columns. Same bug class as foryou's.
- Prod test data added: personal-org-probe@noizu.com + "Smoke Test" project (org
  1ab158ec); clean up with other probe rows.

The starter-app cutover shipped. Live: release `therobotlearns` (ns `apps`) now runs the
Phoenix backend (`backend:v1.0.2`) + Next.js frontend (`frontend:v1.0.1`) behind one
ingress; the static-site chart era is over (legacy `web` image + `helm/therobotlearns`
chart retained for rollback only).

## Shipped & verified

- [x] Infisical: `/apps/therobotlearns` (8 keys) + `/platform/authentik` TRL OIDC pair pushed; dry-runs clean; foryou untouched
- [x] DNS: `app.therobotlearns.com` A record (proxied) applied via terragrunt
- [x] Helm cutover rev 8+ — chart renamed `start-app`→`therobotlearns` so resources adopted the legacy names in place (selectors matched; ingress collision solved); rev-7 strays pruned manually
- [x] `therobotlearns-secrets` + `therobotlearns-tls` materialized by Infisical operator from chart-rendered CRDs
- [x] Liquibase: 71 changesets applied via `echo yes | liquibase-shell therobotlearns -- update`
- [x] appDomain support ported into TRL chart (ingress second host rule, APP_URL/COOKIE_DOMAIN env, FRONTEND_URL default) — vendored copy predated it
- [x] Verified: landing 200 · `/auth/oidc` 302 → Authentik authorize w/ correct client+callback · providers endpoint lists oidc · register w/o invite 422 fail-closed · register w/ TRL- invite 201 + login 200 · waitlist plain → "waitlist", w/ invite → "invited" · app.therobotlearns.com 307 → /login?redirect · no pricing copy · /health 200

## Backend fixes shipped in v1.0.2

- `auth_controller.ex`: catch-all error clause crashed (`String.Chars` on `{:user_name, :invalid}` tuple) → 500; now formats tuples → clean 422
- `user_name` defaulted to full email (always fails `^[a-zA-Z0-9_-]+$` ≤32) → now derives sanitized local part
- `create_invite_token/1` generated url-base64 raws that could never satisfy the `TRL-` regex enforced by waitlist + landing modal → now emits `TRL-<Base32>`

## Left open (deliberate)

- [ ] OIDC browser round-trip: Keith's 2026-07-23 test traversed Authentik → backend callback → frontend sso-callback correctly but hit `sso_unavailable` (SSO_DOMAINS was unset = default-closed). Fixed same day: `sso.domains "noizu.com=oidc;therobotlives.com=oidc"` + autoApproveDomains wired through new helper block; providers endpoint confirms policies. Awaiting one more login retry to close.
- [ ] App-shell branding is still scaffold copy ("Start-App: Tagline" header on /login etc.) — landing was ported but the authed shell wasn't; needs TRL naming/theme pass.
- [ ] Invite issuance has no HTTP/admin surface — mint via rpc: `bin/the_robot_learns rpc 'TheRobotLearns.Organizations.create_invite_token(%{max_uses: N, note: "..."})'`. A live 10-use invite from verification exists (note "cutover verification 2026-07-23"); revoke or reuse.
- [ ] Test data in prod DB: users `cutover-probe@noizu.com`, waitlist rows `cutover-waitlist*-probe@noizu.com`, one 1-use-consumed invite — clean or keep
- [ ] Mail is unconfigured (SENDGRID key empty in values) — verification/magic-link emails silently disabled
- [ ] OTEL exporter econnrefused log spam (localhost:4318) — no collector sidecar; point at cluster collector or disable
- [ ] Rotate `authentik_api_token` + `authentik_bootstrap_password` "when we start marketing" (Keith's explicit deferral; transcript exposure 2026-07-22)
- [ ] Uncommitted changes on `develop` — backend fixes, chart rename+templates, values v1.0.2/v1.0.1, `.infra-config.yaml`, zone terragrunt, tomorrow.md
- [ ] Remove legacy static chart/`web` image after soak; drop rollback note in `.infra-config.yaml` comment
- [ ] deploy-service `--tag vX.Y.Z` builds+pushes fine but errors at promotion (wants `vM.m.edge`) and aborts first-release promotion headless — workaround used: `docker-build --prod --push --vsn vX.Y.Z` + hand-pin values; consider tool fix
