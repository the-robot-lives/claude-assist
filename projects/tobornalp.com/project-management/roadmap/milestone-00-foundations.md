---
title: "Milestone 0: Baseline Audit & Platform Contracts"
milestone: M0
status: draft
generated: 2026-07-16
---

# M0 — Baseline Audit & Platform Contracts

See [README.md](README.md) for lane ownership, the full story matrix, migration ID
scheme, and roadmap-wide flags.

## Goal

M0 delivers no user stories. It is enabling work: audit what already exists,
ratify the shared decisions every lane's schema and UI will depend on, and stand
up the platform shell and conventions — so that M1's 10 lanes can start in
parallel without touching each other's files or re-deriving decisions that
should be made once, centrally.

Staffing: a small crew — WS-L (platform) plus one auditor per epic cluster
(roughly one auditor per lane, pulled in for task 1 and then released back to
their lane for M1).

## Entry criteria

None. M0 starts immediately; it has no upstream milestone.

## Task groups

### 1. Gap audit — map existing code to the 100 stories

**Owner:** WS-L, with one auditor per epic cluster (one per lane, part-time).

Cross-reference the 241 existing backend `.ex` files and Liquibase changelogs
001–035 against all 100 user stories to determine, per lane, what's done,
partial, or absent. Consult `app/docs/PROJ-ARCH.md`, `app/docs/PROJ-LAYOUT.md`,
and `app/docs/PROJ-SCHEMA.md` for the current architecture/schema baseline
before diffing against story requirements, and read changelogs 001–035 directly
for what's already migrated (items-queues, OKRs, notifications, and
user-consent are known to have existing coverage — confirm exact scope).

Subtasks:
- Inventory `app/backend/lib/therobotplans/**` by lane-owned domain path (see
  README lane table) and tag each module against the story/stories it partially
  or fully implements.
- Walk changelogs 001–035 and record which tables/columns already exist for
  each lane's future schema needs (avoids duplicate migrations in M1+).
- Cross-check `PROJ-SCHEMA.md` against the actual changelog state — flag any
  drift for a doc-update follow-up (does not block M0 exit, but must be filed).
- Produce the audit-matrix appendix: one row per story, columns for
  done/partial/absent, existing module(s)/changelog(s) if any, and a one-line
  note for the owning lane on what M1 needs to extend vs. build fresh.

**Deliverable:** `audit-matrix` appendix (published alongside this doc or as a
linked artifact) — every lane reads its rows before writing its first M1 line
of code.

### 2. Core Item polymorphism decision

**Owner:** WS-L, ratified with lane leads (todo/bug/incident/doc/goal owners:
WS-A, WS-D, WS-F, WS-G, WS-I).

Decide whether todo/bug/incident/doc/goal share a base `Item` schema/behavior
(polymorphic entity with per-domain extension tables) or remain fully separate
per-domain entities. This decision informs every lane's M1 schema design and
the migration ID each lane allocates, so it must close before any lane writes
its M1 changelog.

Subtasks:
- Evaluate polymorphic-base vs. separate-entity against the existing
  `noizu_labs_entities` patterns already used elsewhere in the codebase.
- Decide the shared fields (owner, org scope, status, timestamps, agent
  assignee reference) vs. domain-specific fields per lane.
- Publish the decision as a short ADR-style note plus a base schema stub (if
  polymorphic) that lanes extend in M1.

**Deliverable:** Item polymorphism ADR + base schema stub (if applicable).

### 3. Event bus + notification service contracts

**Owner:** WS-L.

Define the publish/subscribe contract every lane uses to emit and consume
cross-lane events (e.g., deploy completed, incident opened, bug SLA breach),
and the notification service interface lanes call into rather than building
their own delivery paths (consumed directly in M2 by US-046 pipeline-failure
notifications, and referenced by several M3 stories).

Subtasks:
- Define event envelope shape (event type, org/actor scope, payload schema
  versioning) and the topic/channel naming convention.
- Define the notification service's public interface (enqueue, preference
  lookup, delivery channels) — this is the contract US-082 (agent notification
  prefs) and US-046 build against later.
- Document who owns topic namespaces per lane (each lane owns its own event
  types; WS-L owns the bus infra and the shared envelope schema).

**Deliverable:** event bus contract doc + notification service interface doc.

### 4. Agent runtime contract

**Owner:** WS-J (agent platform lane), ratified with WS-L.

Define how AI agents receive, execute, and report on tasks — the contract
WS-J's M1 story (US-076 agent team dashboard) implements against, and that
every later "AI does X" story (US-018, US-023, US-034, US-060, US-071, and
others) ultimately calls into.

Subtasks:
- Define the task assignment interface (how a task/item gets an agent
  assignee — this is the "WS-J assignee contract" referenced by US-024 in M2).
- Define the execute/report lifecycle (states, progress reporting, failure/
  retry semantics) and how it surfaces in the agent audit log (US-078, M3).
- Define how agent cost/usage is captured at the runtime level (feeds US-085
  agent cost tracking in M4 and the M3 exit criterion on genai cost
  instrumentation).

**Deliverable:** agent runtime contract doc, consumed by WS-J starting M1.

### 5. Frontend app shell

**Owner:** WS-L.

Stand up the `/app/[orgId]` layout, navigation skeleton, and the route-segment
registration convention every lane's M1 frontend story plugs into
(`app/app/[orgId]/<lane-segment>/**`).

Subtasks:
- Build the `[orgId]` layout shell (org context provider, auth guard reuse,
  top-level nav shell) as a single WS-L-owned file tree.
- Define the route-segment registration convention (how a lane adds its
  `personal/`, `inbox/`, `projects/`, etc. segment without editing the shared
  layout file) and the `today/**` placeholder WS-L will fill in M2 (US-001).
- Wire the nav skeleton with placeholder entries per lane, so M1 lanes only
  need to fill in their own segment, not touch the nav file directly (nav
  entries beyond the placeholder set route through an WS-L interface ticket
  per the shared-hotspot-file rule).

**Deliverable:** merged app shell; route-segment convention doc.

### 6. Component spec → styleguide primitive mapping

**Owner:** WS-L.

Map the ~78 component specs under `project-management/components/` to
`@noizu/styleguide` primitives, and generate the shared `components/ui/**`
and `components/generated/**` base set lanes build their domain components on
top of.

Subtasks:
- Walk the component specs and classify each as "maps directly to an existing
  styleguide primitive," "needs a thin wrapper," or "net-new shared
  component."
- Generate the shared base set for the "wrapper" and "net-new shared" buckets
  into `components/ui/**` / `components/generated/**`.
- Publish the mapping table so each lane knows, per component in its spec set,
  which shared primitive to build on rather than duplicating.

**Deliverable:** component mapping table + generated shared component base
set.

### 7. Test harness + CI conventions

**Owner:** WS-L.

Set the mise task conventions and Cypress scaffold pattern every lane's tests
follow, so CI wiring is uniform across 12 lanes.

Subtasks:
- Define/extend `mise` tasks for backend (`mix test` per domain) and frontend
  (per route-segment) test runs, plus the aggregate CI task.
- Scaffold the Cypress+cucumber pattern per route segment (one feature-file
  directory convention per lane, consistent with existing auth/onboarding
  Cypress setup) so M1 lanes copy the pattern rather than invent their own.
- Confirm the pattern covers the liquibase-per-lane changelog include file
  convention (`db/changelog/lanes/<lane>.yaml`) referenced in the migration ID
  scheme.

**Deliverable:** mise task conventions + Cypress scaffold template.

### 8. Ratify lane ownership + migration allocation

**Owner:** WS-L, sign-off from all lane leads.

Formally ratify this roadmap's lane ownership table and the migration ID
block allocation scheme (see [README.md](README.md#migration-id-allocation))
as binding for the remainder of the roadmap.

Subtasks:
- Confirm every lane lead has reviewed and accepted their owned backend/
  frontend paths (no contested ownership going into M1).
- Confirm the migration block offsets (WS-A 00–04 .. WS-L 55–59 within each
  milestone's `x00` base) and that M0's own migrations, if any, use 090–099.
- Publish both as binding references linked from every subsequent milestone
  doc.

**Deliverable:** ratified lane ownership + migration allocation (this is
already captured in README.md; M0's job is sign-off, not re-authoring).

## Contracts produced in M0

| Contract | Producer | First consumed by |
|----------|----------|--------------------|
| Audit matrix | WS-L + per-lane auditors | All lanes, M1 kickoff |
| Item polymorphism ADR | WS-L + lane leads | All lanes' M1 schema design |
| Event bus + notification service interface | WS-L | US-046 (M2), US-082 (M2) |
| Agent runtime contract | WS-J | US-076 (M1), US-078/US-080 (M3), US-085 (M4) |
| App shell + route-segment convention | WS-L | Every lane's M1 frontend story |
| Component → styleguide mapping | WS-L | Every lane's M1+ frontend work |
| Test harness + CI conventions | WS-L | Every lane, M1 onward |
| Ratified lane ownership + migration allocation | WS-L | Every lane, M1 onward |

## Exit criteria

- All contracts above are published (not just drafted).
- The `/app/[orgId]` shell is merged to the main branch.
- The audit matrix is published and linked from this doc.
- Every lane lead has signed off on their owned paths and migration block.
- No lane needs to touch a shared/hotspot file to start its M1 story — if it
  does, that's a signal M0 isn't actually done.
