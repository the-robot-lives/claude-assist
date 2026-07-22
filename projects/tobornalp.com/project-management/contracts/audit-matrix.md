---
title: Baseline Audit Matrix — Story → Substrate Status
lane: WS-L (Platform Shell & Cross-Domain)
milestone: M0 (Baseline Audit & Platform Contracts)
status: draft — M0 audit deliverable
grounded_against: app/backend commit on branch feat/ex-litellm (241 .ex files); changelogs 001–034; app/frontend (Next.js 16)
row_source: project-management/roadmap/README.md (US-001..US-100)
---

# Baseline Audit Matrix

What substrate already exists for each of the 100 roadmap stories, so a lane extends rather
than duplicates. Grounded in a full read of `app/backend/lib/therobotplans/` and
`app/frontend/src/app/` (recon 2026-07-22).

## Legend

| Mark | Meaning |
|---|---|
| **done** | Story's core capability is live and usable through a shipped surface (REST or UI). |
| **partial** | Substrate (schema/domain/logic) exists but the story's own surface or depth is missing. |
| **absent** | Greenfield for this codebase — no domain module, schema, or surface. |

"REST" = HTTP controller in `router.ex`. "MCP" = tool under `domains/<d>/tools/`. A capability
can be MCP-only (agent-reachable) while absent from REST (UI-unreachable) — called out where
it matters, because chunk A closes exactly those gaps.

---

## Substrate reality (the three built domains + platform)

Only **three** business domains exist today: `domains/items`, `domains/goals`,
`domains/notifications`. Everything else in the lane table is greenfield. Platform
(auth/authz/org/PBAC/media/admin/MCP) is deep and reusable.

| Subsystem | Status | Anchor | Notes |
|---|---|---|---|
| Items (polymorphic work primitive) | **done** | `domains/items`, `schema/item.ex`, ch034 | CRUD, human keys, rank/dates/estimate, links, definitions, events. See ADR-001. |
| Boards / queues (methodology-aware) | **done** | `schema/item_queue.ex`, `board_stage.ex`, `board_iteration.ex` | queue + stage + iteration + lexorank; REST `resources /queues`. |
| Item events (append-only history) | **partial** | ch034 `item_events` | write path live; **read/history/burndown views absent** until per-lane M2–M3. |
| Tri-scoped custom fields / types | **done** | `domains/items/definitions.ex` | project>org>global, tombstones; REST `/definitions/{fields,types}`. |
| OKRs (objectives/KRs/check-ins) | **done** | `domains/goals` | parent_id cascade, item-backed KR auto-progress, objective_progress rollup; REST `OkrController`. |
| Notifications (per-recipient inbox) | **done** | `domains/notifications` | notify/get/poll/ack, dedup, rate-limit, per-org PubSub topic; REST index/count/mark_read. |
| Today aggregation | **partial** | `today.ex`, `TodayController` | live monolith (4 inlined queries); **not provider-based** — refactor per Today Read-Model Contract. |
| Comments / attachments / watches / item-links | **partial (MCP-only)** | `schema/{comment,attachment,watch,item_link}.ex`, `domains/items/tools/item_{comment,attach,watch,link}.ex` | tables + MCP tools exist; **no REST controllers** → UI-unreachable until chunk A adds REST. |
| Event bus | **partial** | `events.ex` | topic `"events"`, **fixed 6-type allowlist** (user/org only); no item/goal/incident/agent events — extend per event-bus contract. |
| Phoenix channels | **partial** | `channels/{user_socket,org_channel}.ex` | only `org:<id>`; no `today:*` or `notifications:*` channel. |
| Auth / SSO / magic-link / OTP | **done** | `AuthController`, `SSOController`, Samly SAML, OIDC | full. |
| PBAC authz (policies, roles, memberships) | **done** | `Authz`, `PolicyController`, `CustomRoleController` | **user-bound principal only** (no agent principal — see Agent Runtime Contract). |
| Organizations / projects / members | **done** | `OrganizationController`, `ProjectController` | project CRUD + members + archive. |
| Media (presign/upload/serve) | **done** | `MediaController`, `MediaServeController`, `schema/media/**` | full. |
| Admin (users/orgs approve) | **done** | `AdminController` | full. |
| MCP multi-server plane | **done** | `router.ex` host-scopes, `domains/*/mcp.ex` | `projects.`/`items.`/`notifications.`/`goals.` + root aggregator. |
| **Agents / personas / registry** | **absent** | — | greenfield; Agent Runtime Contract published (M0). |
| **GenAI/LLM wiring** | **absent** | `{:genai}` dep only | zero usage, no `llm_models` table. |
| **saved_views** | **absent** | — | no table/schema; smart-lists/portfolio/kanban-view persistence is greenfield. |

### Frontend surface (8 product screens live)

`page.tsx` files under `app/[orgId]/`: **today, items, items/[itemId], items/boards/[boardId],
goals, inbox, members**, plus the org root `page.tsx`. Outside the shell: auth/onboarding
flow (login, signup, register, verify, forgot-password, sso-callback, pending-approval,
complete-registration), `admin/{orgs,users}`, `profile`, `styleguide`. **No** personal,
projects, bugs, pipelines, monitoring/status, wiki, agents, or prompts routes exist yet —
they are the lanes' M1+ frontend work.

---

## WS-A — Personal Items & Habits

Base primitive (items + due_date + assignee) is live; **no `domains/personal`, no habits,
no personal route** (`items` route is generic, not personal-scoped).

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-011 personal todo w/ due date | M1 | **partial** | items CRUD + `due_date` column + REST `resources /items` all live; missing: personal-scoped domain + `/app/:org/personal` route + Today personal provider. Build on `Schema.Item` (item_type `todo`, project_id NULL). |
| US-012 recurring habits | M2 | **absent** | model as items + recurrence rule; no schema. |
| US-014 habit streaks | M2 | **absent** | depends US-012. |
| US-015 smart lists | M2 | **absent** | needs `saved_views` (absent). |
| US-016 life-alongside-work view | M2 | **absent** | view over personal+work items. |
| US-017 time blocking | M2 | **absent** | no calendar/time-block schema. |
| US-020 archive completed | M2 | **partial** | `status` done/closed exists; no archive surface/filter. |
| US-018 AI morning planning · US-019 AI weekly review | M3 | **absent** | needs GenAI wiring (absent) + M2 WS-A. |

## WS-B — Inbox & Capture

`inbox` route page exists (stub); **no `domains/inbox`**, no capture/triage/ingestion.

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-006 quick capture anywhere | M1 | **partial** | `inbox/page.tsx` stub exists; no capture domain/endpoint. Capture writes → items. |
| US-007 mobile capture | M2 | **absent** | depends US-006. |
| US-008 AI inbox triage | M2 | **absent** | needs GenAI wiring. |
| US-009 email-to-inbox | M2 | **absent** | inbound mail pipeline greenfield. |
| US-010 voice capture | M2 | **absent** | transcription pipeline greenfield. |

## WS-C — Projects & Delivery

Strongest non-OKR substrate: projects, items, methodology-aware boards, stages, iterations,
lexorank all live. FE has items/boards/[itemId].

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-021 create project w/ methodology | M1 | **partial** | `ProjectController` full CRUD + members + archive live; `item_queue` is methodology-aware. Missing: methodology-selection depth + `/app/:org/projects` route (only `/items` today). Near-complete substrate. |
| US-022 kanban board view | M2 | **partial** | stage+rank substrate + `items/boards/[boardId]` route live; needs drag/column UI + reorder write (rank is ready). |
| US-024 assign to agents or humans | M2 | **partial** | `assignee` is a free string (human works); agent principal **absent** — gated on WS-J assignee contract (US-076). |
| US-025 multi-project portfolio | M2 | **absent** | needs `saved_views`/rollup; greenfield. |
| US-026 per-project methodology | M2 | **partial** | queue methodology field exists; enforcement/switching UI absent. |
| US-030 project templates | M2 | **absent** | no template schema. |
| US-023 sprint planning AI · US-028 backlog grooming AI | M3 | **absent** | needs GenAI wiring. |

## WS-D — Bugs & Quality

**Fully greenfield as a lane**, but rides the item primitive (ADR-001): a bug is
`item_type: "bug"` + a `bug` type-definition. No `domains/bugs`.

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-033 bug capture + auto-enrichment | M2 | **absent** | build as item_type `bug` + `item_type_definition` (severity/repro fields). Depends US-011/US-021 base. |
| US-036 bug SLA tracking | M2 | **absent** | SLA states via `status_workflow` on the bug type-def. |
| US-034 AI auto-triage · US-037 duplicate detection · US-038 root-cause · US-035 bug↔incident | M3 | **absent** | US-037 needs pgvector; US-035 needs WS-F. |
| US-039 bug-to-deploy · US-040 customer intake | M4 | **absent** | greenfield. |

## WS-E — CI/CD & Deploy

Fully greenfield. No `domains/cicd`, no pipeline/deploy/environment schema.

| Story | M | Status | Note |
|---|---|---|---|
| US-041 pipeline status view | M1 | **absent** | greenfield vertical. |
| US-042 deploy transitions · US-044 deploy changelog · US-045 env dashboard · US-046 failure notifications | M2 | **absent** | US-044 builds the shared changelog service (Flag 2); US-046 consumes WS-L notification contract (live). |
| US-043 rollback · US-047 approval workflow | M3 | **absent** | US-047 gated on US-077 (agent roles). |

## WS-F — Monitoring & Incidents

Fully greenfield. No `domains/monitoring`, no incident/SLO/status-page schema, no
`app/status` public route (roadmap names it; not present). WS-F is a **Today provider**
(incidents) per the Today Read-Model Contract.

| Story | M | Status | Note |
|---|---|---|---|
| US-048 uptime dashboard | M1 | **absent** | greenfield vertical. |
| US-049 alert-to-incident · US-050 SLO tracking · US-053 status page | M2 | **absent** | greenfield. |
| US-051 incident timeline · US-052 on-call · US-055 post-incident review | M3 | **absent** | greenfield. |
| US-054 anomaly correlation | M4 | **absent** | needs GenAI + metrics history. |

## WS-G — Docs & Knowledge

Fully greenfield. No `domains/docs`, no wiki/ADR/runbook schema. (This repo has an external
tobor-wiki MCP, unrelated to the app DB.)

| Story | M | Status | Note |
|---|---|---|---|
| US-056 structured wiki | M1 | **absent** | greenfield vertical. |
| US-057 living-docs/code-link · US-058 ADR tracking · US-060 stale-doc agent · US-063 doc templates | M2 | **absent** | US-060 needs GenAI. |
| US-059 runbook · US-061 auto-changelog · US-062 KB search | M3 | **absent** | US-061 consumes shared changelog svc (Flag 2); US-062 needs pgvector/FTS. |

## WS-H — Checklists & Templates

Fully greenfield. No `domains/checklists`. Embedded UI (no own route until US-067).

| Story | M | Status | Note |
|---|---|---|---|
| US-064 reusable checklists | M1 | **absent** | greenfield vertical. |
| US-065 checklist enforcement · US-066 agent-generated checklists | M2 | **absent** | US-066 needs GenAI. |
| US-067 unified template library · US-068 pre-deploy checklist | M3 | **absent** | US-067 consumes US-030/US-063 template contracts; US-068 consumes WS-E. |

## WS-I — Goals & OKRs

Substantially built — `domains/goals` is one of the three live domains.

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-069 OKR hierarchy | M1 | **partial→done** | `Objective` parent_id cascade (company→team→individual→personal), `KeyResult`, `OkrCheckin`, REST `OkrController` (index/create/show/update + key_results + checkins), FE `goals/page.tsx` all live. Missing only hierarchy-viz depth. Extend, don't rebuild. |
| US-070 auto-progress KRs | M2 | **done** | `Goals.recompute_progress/1` + `kr_item_links` + `item_status_changed/1` hook live; `auto_progress` flag on KR. |
| US-072 goal alignment viz | M2 | **partial** | cascade data (`parent_id`) + `objective_progress/1` rollup live; visualization UI absent. |
| US-073 OKR scoring | M2 | **absent** | scoring formula/field not modeled. |
| US-071 check-in agent · US-074 personal OKRs (merged w/ US-013) · US-075 retrospective | M3–M4 | **partial/absent** | check-in schema (`OkrCheckin`) live; the *agent* is absent (GenAI). |

## WS-J — Agent Platform & Governance

**Fully greenfield** — no `domains/agents`, no agent/persona entity, no GenAI wiring, PBAC
principal is user-bound. **Agent Runtime Contract published (M0)** — the interface all AI
stories build against.

| Story | M | Status | Note |
|---|---|---|---|
| US-076 agent team dashboard | M1 | **absent** | build `domains/agents` per Agent Runtime Contract §1/§4/§8/§9. |
| US-077 roles/permissions · US-079 task queue · US-081 pause/resume · US-082 notif prefs | M2 | **absent** | US-077 = parallel agent PBAC (contract §2); gates M3. |
| US-078 audit log · US-080 metrics · US-083 custom agents | M3 | **absent** | greenfield. |
| US-084 collaboration · US-085 cost tracking | M4 | **absent** | greenfield. |

## WS-K — Prompts & Evaluation

Fully greenfield **in this app**. No `domains/prompts` or `domains/evals`. (NPL implements
prompt versioning in a *different* application — not reusable here.)

| Story | M | Status | Note |
|---|---|---|---|
| US-086 prompt versioning | M1 | **absent** | greenfield vertical. |
| US-087 history · US-088 tags · US-090 restore · US-093 annotations · US-094 export · US-096 rate output | M2 | **absent** | US-096 consumes WS-J data contract (US-076). |
| US-089 compare · US-092 sharing · US-095 audit trail · US-097 eval rubrics | M3 | **absent** | US-092/095 gated on US-077/US-078. |
| US-091 template library · US-098 eval dashboard · US-099 A/B · US-100 feedback loop | M4–M5 | **absent** | capstone US-100 (M5). |

## WS-L — Platform Shell & Cross-Domain

Shell + cross-cutting substrate largely live; the M2+ stories are aggregation/refactor work.

| Story | M | Status | Note / pointer |
|---|---|---|---|
| US-001 unified today dashboard | M2 | **partial** | `today.ex` + `TodayController` + `today/page.tsx` live as a **monolith**; refactor to provider-merge per **Today Read-Model Contract**. Consumes WS-A/C/F/J providers. |
| US-002 agent activity feed · US-005 unified stream | M3 | **absent** | needs event-history read model + WS-J. |
| US-003 drag reorder priorities | M3 | **partial** | item `rank` (lexorank) live; Today override persistence absent. |
| US-004 cross-project today summary | M3 | **absent** | rollup over Today entries. |

---

## Cross-cutting gaps that unblock multiple lanes (M0/chunk-A priorities)

1. **REST for comments/attachments/watches/item-links** — tables + MCP tools exist, **no
   REST** → the item detail UI (`items/[itemId]`) can't show them until chunk A adds
   controllers. Blocks the daily-use surface of WS-A/C/D.
2. **Event-bus allowlist** — fixed 6 user/org events; item/goal/incident/agent events must
   be added (event-bus contract) before Today live-refresh (§6 of Today contract) and any
   cross-lane reaction works.
3. **GenAI/LLM wiring** — `{:genai}` dep present, zero usage. **Every M3 AI story across all
   lanes** (US-008/018/019/023/028/034/054/060/066/071 …) is blocked until WS-J/WS-L wires a
   provider + `llm_models`. Single highest-leverage greenfield.
4. **`saved_views`** — absent; blocks smart-lists (US-015), portfolio (US-025), and any
   persisted filtered view.
5. **Agent principal in PBAC** — user-bound today; the parallel agent PBAC (Agent Runtime
   Contract §2) unblocks agent-assignment (US-024) and all WS-J.

## Confidence / caveats

- Frontend depth per screen not audited beyond route existence — a `page.tsx` may be a stub
  (e.g. `inbox`). "partial" on FE means "route exists," not "feature-complete."
- Story→status inferred from substrate presence, not from running each story's AC. A
  "partial" may still need substantial surface work.
- M3–M5 marked mostly **absent** at lane-summary granularity where the whole lane is
  greenfield — per the task brief, not expanded per-story.
