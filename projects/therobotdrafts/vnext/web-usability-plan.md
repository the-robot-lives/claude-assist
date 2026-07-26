# vnext Web-Usability Plan — from demo to product

Scope: what it takes to make the HoloGraph web app genuinely usable — persisted UML,
per-user workspaces, GitHub round-trip, files/import-export. Grounded in the 2026-07-27
backend/frontend audit (see scratchpad maps; key facts restated inline so this doc stands alone).

Starting position — better than expected:
- Auth/org/PBAC is **real and mature** (Guardian JWT, OIDC/SAML/social SSO, orgs, projects,
  PBAC v2 scoped_memberships/policies, DB-backed invites, admin surface). Nothing to build here.
- Persistence tables **already exist but are unwired**: `graph_documents`,
  `graph_document_versions`, `collab_events` (changelog 026) — jsonb document + version
  snapshots + idempotent collab event log. The `HoloGraph.Docs` context reads disk fixtures
  and never touches the Repo.
- The frontend talks only to its **own Next.js mock routes** (`src/app/api/v1/docs*`), which
  echo without persisting.
- Two incompatible "GraphDocument" shapes exist: the frontend's real 3D-UML type
  (nodes w/ `kind/uml/trd3d`, typed UML edges) vs the backend's placeholder lanes/kanban
  fixture struct. Two incompatible "PatchOperation" shapes too: frontend semantic ops
  (`add_node/connect/rename/reparent/delete`) vs backend JSON-Patch (`add/remove/replace/...`).
- GitHub repo integration and per-user workspaces: confirmed absent everywhere. Greenfield.

---

## Phase 1 — Save UML to the database (the unlock)

**Decision: the frontend's UML `GraphDocument` type is canonical.** The backend's
lanes/kanban fixture struct is a self-described placeholder — retire it. The jsonb
`document` column stores the frontend shape verbatim; backend validates the envelope
(id/slug/title/version/nodes[]/edges[]) and treats node/edge internals as opaque-ish,
mirroring the frontend's `normalizeGraphDocument()` sanitization rules server-side.

**Decision: semantic patch ops are the wire protocol.** Keep
`add_node/connect/rename/reparent/delete` (matches the editor's undo history 1:1); store
each batch verbatim in `collab_events.patch` (dedup on `client_event_id` — the table was
designed for exactly this), and materialize a full snapshot into
`graph_document_versions` every N patches or on explicit Save. JSON-Patch translation
buys nothing today and costs a mapping layer on both ends.

Backend (Phoenix):
1. Rewrite `HoloGraph.Docs` context against `HoloGraph.Repo` + the 026 schemas
   (create/get/list/update/apply_patch_batch/list_versions/restore_version).
2. Routes (`:authenticated`, org/project-scoped via existing PBAC helpers):
   - `GET  /api/v1/projects/:project_id/docs` — list (summary rows: id/slug/title/version/counts/updated_at)
   - `POST /api/v1/projects/:project_id/docs` — create
   - `GET  /api/v1/docs/:id` — full document
   - `PUT  /api/v1/docs/:id` — full-document save (optimistic-lock on `version`; 409 on mismatch)
   - `POST /api/v1/docs/:id/patches` — patch batch → new version (autosave path)
   - `GET  /api/v1/docs/:id/versions` + `POST /api/v1/docs/:id/versions/:v/restore`
3. Keep fixture import as a seed path only (`import_fixture` behind admin).

Frontend:
4. Point the workspace's persistence at Phoenix (env-switched base URL + JWT from the
   existing auth context) and delete the Next.js mock handlers once parity is reached.
   localStorage stays as offline draft/crash-recovery cache, not source of truth.
5. Autosave = debounced patch batches (the status strip's "autosaved · vN" becomes real).

Exit criteria: create → edit → reload → same diagram, from another browser, per version history.

## Phase 2 — Per-user workspaces & files

**Decision: personal workspace = auto-provisioned personal org** (the therobotlearns
pattern), not a new resource_type. On first login create `<user>'s workspace` org + a
default "Drafts" project; docs always hang off a project_id. Zero PBAC changes — sharing
a doc = inviting to the project via existing scoped_memberships; org docs work identically.

- Browser dock **Files** tab ← real per-project doc list; **Recents** ← server MRU
  (`GET /users/me/recent-docs`, simple table or reuse collab_events actor index).
- New Model / Open… / Save As… / Delete Diagram menu items wire to Phase-1 routes.
- Media attachments ("Paste Image as Node", "Attach Image to Face"): the presign
  upload flow already exists (`/media/presign|register`) — flip the `file_uploads`
  feature flag, verify the flag is actually enforced at the route (audit found
  enforcement point unverified), key uploads to the doc's project.

## Phase 3 — GitHub round-trip

All greenfield; the only existing GitHub code is social **login** (ueberauth), which is
unrelated — do not overload it.

1. **GitHub App** (repo-scope, installed per org/user account) — new `repo_links` table:
   project_id, installation_id, repo, branch, path prefix, sync mode.
2. **Import (repo → model)**: pick repo/path → Oban job fetches sources via the App
   token → code-ingest into a GraphDocument. The regex-based TS parsers
   (`importCodeFiles`, `importPlantUml` in `document-io.ts`) get ported to Elixir for
   server-side ingest; client-side paste-import stays as-is.
3. **Emit (model → repo)**: "Emit to Code…" / Code Export Wizard writes generated
   skeletons + `.trd-yaml` to a branch and opens a PR (never direct-to-main). Oban job;
   surfaces in the status-strip task spinner.
4. **Round-trip (shadow files)**: webhook receiver route (`POST /webhooks/github`,
   HMAC-verified — the outbound WebhookHandler is unrelated, inbound is new) on push →
   diff shadow files → re-ingest → propose a model patch batch the user reviews in-app
   ("Re-ingest Edits" menu item becomes real).
5. **"Codespaces"**: ship as deep-links first — "Open in GitHub / github.dev /
   Codespace" on the linked repo/branch (near-zero cost, real value). Self-hosted
   per-user editor pods (code-server on the k8s cluster) are a separate infra project;
   defer until PR round-trip proves out. (Menu: Code ▸ Shadow Files ▸ Open in Editor.)

## Phase 4 — Export/import, server-side

- Text exports (PlantUML/Mermaid/DOT/JSON/code skeletons) already work client-side —
  keep them client-side for interactive use; add `POST /docs/:id/export` backed by the
  same generators ported to Elixir only when CI/headless export is wanted (with
  `graph_documents` live, a CLI/CI can hit the API — that's when server export pays).
- Snapshot PNG: client canvas capture → existing media upload flow.
- XMI / .qea import: heavy parsers exist in the .NET tooling (172/172 round-trip-stable
  trd-yaml converter). Wrap that converter as a small containerized service the backend
  Oban job shells to, rather than re-porting to Elixir. Later-phase; PlantUML/Mermaid/
  code cover the common path.

## Phase 5 — Realtime collab (already half-designed)

`collab_events` (client_event_id dedup) + Phoenix Channels (UserSocket auth already
JWT-wired) + the CollabStrip UI (currently mock) line up: per-doc channel, broadcast
applied patch batches, presence for the strip. Do after Phase 1 settles the patch
protocol — the same patch batch envelope is the broadcast payload.

## Phase 1.5 — Launch surface (operator-requested 2026-07-27)

- **Landing page at `/`**: marketing page (product pitch, screenshot/canvas hero, CTA).
  Workspace moves to `/studio`; anonymous demo mode stays reachable via "Try it" CTA
  (logged-out workspace = LocalDraftStore, preserved by the Phase-1 switch-over).
  Retarget e2e specs that visit `/` for the workspace.
- **Auth UX**: password login already real (backend + /login page). Add Authentik as a
  generic-OIDC provider: seeded `auth_providers` row, env-driven client config
  (confidential client, `/auth/oidc/callback` exact redirect — therobotknows lessons),
  SSODomains policy scoped, NOT open-to-any-email. Authentik-side provider/application
  creation is a deploy-time infra step; frontend SSO buttons auto-appear from
  `GET /auth/sso/providers` once the row is live.

## Phase 6 — Electron desktop app (Unity replacement)

Goal: the same vnext app packaged as a local macOS desktop app, superseding the Unity
editor for non-VR use. The web app IS the product; Electron adds the native shell +
local files. (Tauri would be lighter, but Electron is the call: we need full Chromium
for the Three.js canvas and zero engine-difference between web and desktop.)

**Architecture — one frontend, two storage providers.** The critical enabler is a
`DocStore` interface in the frontend, decided NOW during the Phase-1 switch-over so we
don't wire Phoenix calls directly into the workspace:
- `CloudDocStore` — the Phase-1 Phoenix API client (JWT auth, org/project scoping).
- `LocalDocStore` — Electron-only, IPC to the main process: open/save `.trd.json` /
  `.trd-yaml` on disk, native dialogs, MRU, file watching. Local-first, no login needed.
Signed-in desktop users get both (local files + cloud docs in the Files tab); sync =
explicit "push/pull to cloud", not background magic (TRL lesson: cloud is system of
record when connected; files are an ingest/export channel).

**Layout**: `vnext/app/desktop/` — Electron main + preload + electron-builder config;
consumes the frontend as a static export (the workspace is effectively a SPA once the
Next mock API routes die in Phase 1; auth/org pages hit the cloud backend directly).
No local Phoenix, no embedded Postgres — local mode is filesystem-backed.

**Native parity items (what makes it feel like the Unity app):**
1. **Native menu bar** generated from `chrome/menu-data.ts` — one IA tree drives the
   in-app menu bar (web), the Electron native `Menu` (desktop, real ⌘ accelerators),
   and the ⌘K palette. The data-driven menu work in the Concept D rebuild pays off here.
2. **Files**: open/save/save-as dialogs, `.trd-yaml`/`.trd.json` file associations,
   drag-a-file-onto-the-window import, Recents = OS recent-documents + in-app MRU.
3. **Converter sidecar**: bundle the existing net10 trd-yaml/.qea/XMI/PlantUML converter
   (172/172 round-trip stable) as a sidecar binary invoked from main — full Import/Export
   menu goes native without porting parsers anywhere.
4. **Shadow files / round-trip**: chokidar watch on emitted source folders in main,
   "Open in Editor" via VS Code deep-link/`shell.openPath`, re-ingest on change —
   the local twin of Phase 3's GitHub webhook flow, no GitHub required.
5. **DB round-trip**: `pg`/`mysql2` drivers in the main process for the psql/mysql→ERD
   import (Unity feature parity); connects to localhost DBs the browser never could.
6. **Packaging**: electron-builder, notarized DMG (the osx signing runbooks exist in-repo),
   `trd://` protocol handler, electron-updater later.

**What Unity uniquely keeps**: VR. The Electron app replaces the desktop editor;
if/when VR returns it's either the Unity app maintained for that mode only, or WebXR on
the same Three.js scene (unscoped). Risk to watch: Three.js perf on very large models
vs Unity's mesh pipeline — instancing work may be needed before parity claims.

Sequencing: needs Phase 1 (DocStore interface + real API) only. Phases 2–5 all arrive
in the desktop app for free through the shared frontend.

---

## Sequencing & effort (rough)

| Phase | Depends on | Size |
|---|---|---|
| 1 Persistence | — | M (context rewrite + 6 routes + frontend switch) |
| 2 Workspaces/files | 1 | S–M (personal-org provisioning + Files/Recents wiring) |
| 3 GitHub | 1 (2 for per-user repos) | L (App auth, ingest/emit jobs, webhook, PR flow) |
| 4 Server export/import | 1 | S (text) + M (.qea/XMI service wrap) |
| 5 Realtime | 1 | M (channels + presence + conflict policy) |

Recommended order: **1 → 2 → 3**, with 4/5 slotting in behind whichever gets pulled by
usage. Phase 1 alone converts the demo into a usable single-player product.

Open questions for the operator:
- Personal-org naming/slug convention (and whether personal orgs are hidden from the org switcher).
- GitHub App: single Noizu-owned app for all tenants, or per-deployment app config?
- Conflict policy for Phase 5 (last-write-wins per patch batch vs CRDT) — LWW+versions is the cheap start.
