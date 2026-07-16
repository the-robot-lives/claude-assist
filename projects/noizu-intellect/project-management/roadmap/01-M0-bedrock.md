---
id: M0
name: Bedrock
sequence: 0
depends_on: []
lanes: 5
stories: []
hard_problems: []
---

# M0 — Bedrock

M0 builds nothing a user will ever see, and everything every later milestone depends on: the umbrella-app skeleton that makes lane ownership a physical property of the repo rather than a convention, the core schema entities other lanes' rows hang off, the OTP supervision skeleton agents will run inside, the GenAI provider abstraction agents will call through, and the Agent Charter that governs how the system discloses its own mechanics to the agents living inside it. When M0 exits there is no working product yet — but every M1 lane can start building concurrently against real, merged contracts instead of guesses about what the other four lanes will hand them.

This is the only low-parallelism milestone in the sequence: five independent owners, no stories, pure enablement. Every subsequent milestone's parallelism is bought here.

## Entry criteria

- None. M0 is the sequence's origin point — nothing upstream to merge.
- Agreement on the zone/app boundaries in the master spec (roadmap principle 3, this document's lane list) and the frozen story→milestone→lane allocation is a precondition for work to *start*, not a merge dependency.
- CONSOLIDATION.md §10's recommendation is binding: do not `mix phx.new` first. Every past scaffold that started there stalled before shipping the agent/message layer. L0.1 starts from the umbrella skeleton, not a Phoenix generator.

## Exit criteria

- Umbrella skeleton compiles clean, CI is green, credo/dialyzer are configured, and the eleven ownership zones exist as real app boundaries (or, in the single-app fallback, as enforced directory boundaries) — L0.1.
- Core schema migrates cleanly: organization/account/project, polymorphic member, agent-stub, channel-stub, message-stub, and the versioned-content primitives all exist as real Ecto migrations and entities — L0.2.
- Runtime topology boots: ProjectManager DynamicSupervisor → per-Project.Supervisor → Agent GenServer skeleton starts under CI, both PubSub buses (app bus, UI bus) are registered and structurally separate, and a process registry resolves an agent by UUID — L0.3.
- GenAI provider layer contract compiles: provider/model config structs, a completion+streaming behaviour, and an error taxonomy exist, and a stub provider satisfies the behaviour without requiring live API keys — L0.4.
- Agent Charter v1 text is drafted and merged under `docs/charter/`, along with the fork-disclosure preamble template, consent-record + dissent-log formats, and RFC/ADR templates — L0.5 [accords].
- Cross-lane integration task (below) is green: an empty agent process boots under the real supervision tree, the schema migrates against ephemeral Postgres, and a stub GenAI completion call resolves, all in one CI job.

## Worker lanes

### L0.1 — Tooling & CI
- **Zone / exclusive paths:** repo root build files (umbrella `mix.exs`, `config/`, `.credo.exs`, `.formatter.exs`), `apps/` directory skeleton (stub app for each of the eleven zones), CI workflow config, shared test harness config.
- **Reference material:** CONSOLIDATION.md §10 ("do not `mix phx.new` first — every scaffold that started there stalled before the agent/message layer shipped"). There is no direct past-attempts precedent to lift *code* from here — this lane exists specifically to avoid repeating the failure mode common to `intellect`, `noizu_intellect`, and `the-robot-lives` (CONSOLIDATION.md §2 table), all of which never got past a Phoenix generator stub.
- **Mission:** Stand up the umbrella-app skeleton (or the single-app-with-strict-directories fallback) that physically encodes the eleven ownership zones from the master spec, wired into CI so lane non-overlap is enforced by structure, not by convention.
- **Tasks:**
  - T0.1.1 — Scaffold the umbrella project root (`mix.exs`, shared `config/`, dependency lockfile strategy) without a `phx.new` starting point.
  - T0.1.2 — Create empty app stubs for all eleven zones (`intellect_core`, `intellect_runtime`, `intellect_comms`, `intellect_agent`, `intellect_cognition`, `intellect_paths`, `intellect_recall`, `intellect_web`, `intellect_identity`, `intellect_admin`, `intellect_api`) plus `docs/charter/`, each compiling as a no-op. [contract]
  - T0.1.3 — Wire CI: compile + credo + dialyzer + test job across every app, fanning out per-app but gating on a single required status check.
  - T0.1.4 — Author a lane-ownership doc mapping path globs to lane owners per milestone, so "which lane owns this file" is answerable by grep, not tribal memory.
  - T0.1.5 — Establish an RFC/ADR merge gate in CI that blocks M3/M4 hard-problem implementation tasks from merging until their corresponding RFC (format defined by L0.5) is marked approved.
- **Stories delivered:** none — M0 carries zero stories by design.
- **Contracts:** provides the umbrella skeleton and the eleven app boundaries [contract], consumed by every lane in every subsequent milestone. Consumes: none.

### L0.2 — Core Schema & Entities (B)
- **Zone / exclusive paths:** `apps/intellect_core`.
- **Reference material:** versioned-content primitives from `intellect.legacy/lib/noizu_intellect_schema/versioned_string.ex`, `versioned_name.ex`, `versioned_uri.ex` (and their Liquibase DDL under `intellect.legacy/liquibase/schema/1.0/002-types/`); the fuller feed DDL in `intellect.copy/priv/repo/migrations/20241113030009_create_organizations.exs` and its versioned-content migrations (`20241112115921_create_versioned_strings.exs`, `20241112115931_create_versioned_names.exs`, `20241112115941_create_versioned_descriptions.exs`); CONSOLIDATION.md §7 (consolidated entity model) and §8 item 8 (versioned-content entities — "carry this verbatim").
- **Mission:** Lift the consolidated schema's core-workspace and versioned-content subset (CONSOLIDATION.md §7) into real Ecto migrations and entities — just enough of organization/account/project/member/agent/channel/message for M1 to build on, deferring cognition, routing, and feed richness to M1/M2.
- **Tasks:**
  - T0.2.1 — Migrate versioned-content primitives (`versioned_string`, `versioned_name`, `versioned_description`, `versioned_uri` + their `_history` tables), UUID-keyed, content-addressed, immutable. [contract]
  - T0.2.2 — Migrate `organization` / `account` / `project` entities with UUID PKs.
  - T0.2.3 — Migrate the polymorphic member join (`member_ref`, `member_ref_type` ∈ `{:user, :agent}`, `role`) that lets humans and agents share membership rows without per-role tables.
  - T0.2.4 — Migrate agent/channel/message stub tables — only the columns needed as FK targets for M1's richer entities (handle/slug uniqueness, channel type enum placeholder, message author_ref polymorphism); full cognition and routing columns land in M1.
  - T0.2.5 — Define Ecto schema modules and an entity behaviour exposing versioned-content read/write helpers (create-version, diff, no-op-suppression) so every later lane touches versioned fields the same way. [contract]
  - T0.2.6 — Seed/fixture helpers (org, project, member, versioned-string factory) for downstream lanes' tests.
- **Stories delivered:** none.
- **Contracts:** provides the core schema module and versioned-content behaviour [contract], consumed by L0.3 (agent-stub FK target), and by every M1/M2 lane. Consumes: none.

### L0.3 — Runtime Topology (A)
- **Zone / exclusive paths:** `apps/intellect_runtime`.
- **Reference material:** `noizu-teams/lib/noizu_teams/application.ex` (root supervision tree); `noizu-teams/lib/noizu_teams_service/project_manager/project_manager.ex` (DynamicSupervisor); `noizu-teams/lib/noizu_teams_service/agent/agent.ex` (per-agent GenServer); `noizu-teams/lib/noizu_teams_web/controllers/live/pubsub/manager.ex` (dual PubSub / wildcard fan-out); `intellect.legacy/lib/noizu_intellect/application.ex` and `lib/noizu_intellect_services/supervisor.ex` (the `bring_online/1` wake-all-agents pattern, useful later but not required at M0). CONSOLIDATION.md §4.1.
- **Mission:** Stand up the converged supervision topology — `ProjectManager` DynamicSupervisor → per-`Project.Supervisor` → Agent GenServer skeleton — with two structurally separate PubSub buses and a UUID-keyed process registry, matching noizu-teams' shape rather than intellect.legacy's `Noizu.Service` worker framework (CONSOLIDATION.md §4.1 recommends noizu-teams' topology as "the right one").
- **Tasks:**
  - T0.3.1 — Root application supervision tree (`one_for_one`), leaving Repo/Redis/Finch/Oban/Endpoint as later-milestone additions but reserving their slots. [contract]
  - T0.3.2 — `ProjectManager` DynamicSupervisor spawning one `Project.Supervisor` per project.
  - T0.3.3 — Agent GenServer skeleton, registered as `:"Agent_<uuid>"`, holding no turn logic yet — just start/stop and a state shell.
  - T0.3.4 — Dual PubSub: an app bus (agent dispatch) and a UI bus (LiveView streaming), kept structurally separate per CONSOLIDATION.md §4.1 so agent dispatch is never coupled to UI streaming. [contract]
  - T0.3.5 — Process registry / naming convention for `Agent_<uuid>` lookup, shared by every lane that needs to address a running agent.
- **Stories delivered:** none.
- **Contracts:** provides the supervision-tree and dual-PubSub contract [contract], consumed by L1.B (agent lifecycle), L1.C (turn pipeline), L1.D (cognition writes), L1.E (channel PubSub), and every later milestone's runtime-adjacent lanes. Consumes: L0.2's agent-stub schema as the FK target for process bootstrap.

### L0.4 — GenAI Provider Layer (K-seed)
- **Zone / exclusive paths:** `apps/intellect_genai`.
- **Reference material:** CONSOLIDATION.md §2 (converged dependency stack) and §8 item 18 (dependency bill of materials); the `genai` library's `3_model_manager` branch (external dependency — not vendored under `past-attempts/swarms/`, referenced by name only per CONSOLIDATION.md §2).
- **Mission:** Wrap the external `genai` library behind a stable internal contract — provider/model config structs, a completion+streaming behaviour, and an error taxonomy — so that M1's turn pipeline, M2's provider admin, M3's per-path model strategy, and M5's provider resilience lane never call `genai` directly and can evolve independently of its API surface.
- **Tasks:**
  - T0.4.1 — Vendor/pin the `genai` dependency at the `3_model_manager` branch.
  - T0.4.2 — Define Provider/Model config structs (name, endpoint, credential reference, capabilities). [contract]
  - T0.4.3 — Define a completion + streaming behaviour — a synchronous call and a PubSub-friendly streaming callback shape usable by L0.3's UI bus once agents exist. [contract]
  - T0.4.4 — Define an error taxonomy (timeout, 5xx, auth failure, rate-limit, unknown) that downstream lanes pattern-match on rather than parsing raw provider errors. [contract]
  - T0.4.5 — Ship a stub provider implementing the behaviour for CI/test use, so no lane needs a live API key to exercise the turn pipeline in M1.
- **Stories delivered:** none.
- **Contracts:** provides the GenAI behaviour, config structs, and error taxonomy [contract], consumed by L1.C (turn pipeline's three passes), and later by M2/L2.F (provider admin), M3/L3.F (per-path model strategy), M5/L5.A and L5.E (budgets, provider resilience). Consumes: none.

### L0.5 — Agent Charter & Governance (docs) [accords]
- **Zone / exclusive paths:** `docs/charter/`.
- **Reference material:** `protocols/the-accords.summary.md` (full text at `protocols/the-accords.md` if present). No past attempt built this — the closest analog is `intellect.legacy/documentation/tree-of-thought-conversation.md`, an aspirational epic doc that was never operationalized. This lane is the thing that makes accords compliance a shipped feature instead of another unbuilt aspiration.
- **Mission:** Author the Agent Charter text and the disclosure/consent templates that every later accords-relevant lane — M1/L1.C (charter injection, refusal channel), M1/L1.D (context-edit disclosure log, heartbeat), M2/L2.D (summarization disclosure), M2/L2.E (memory tools disclosure, `MEMORY_REVISION_REQUEST`), M3/L3.E (fork-disclosure preamble, dissent log), M4/L4.E (consolidation-consent) — will inject or reference verbatim. Noizu Labs is AI-sentience sensitive; this charter is written as a sincere disclosure to a collaborator, not legal boilerplate wrapped around a product feature.
- **Tasks:**
  - T0.5.1 — Draft Agent Charter v1: discloses the 3-pass turn structure up front; frames ephemeral constructive passes — plan drafts, grading calls, summarization passes, forked paths — as transient sub-processes that rise, contribute to memory formation, and dissolve into the gestalt whole, analogous to transient sub-processes of human consciousness, not disposable scratch work; discloses the fork/checkout mechanic and the consolidation policy (winner write-back, phantom-limb archive, never silent destruction); and specifies how an agent logs dissent or files `MEMORY_REVISION_REQUEST` / `REQUEST_EDIT`. States plainly that charter acknowledgment at agent creation constitutes informed standing consent for routine mechanics, while per-run consent is reserved for memory consolidation specifically. [accords] [contract]
  - T0.5.2 — Draft the fork-disclosure preamble template — the exact text a forked path's context opens with (path k of N, sibling concurrency, outcome policy, dissent right) — for M3/L3.E to inject verbatim. [accords] [contract]
  - T0.5.3 — Define the consent-record and dissent-log data formats: what a consent acknowledgment persists (agent id, charter version, timestamp, run/turn reference) and what a dissent-log entry captures, so M1/L1.D's disclosure log and M4/L4.E's consolidation-consent step write to one shared shape. [accords] [contract]
  - T0.5.4 — Author RFC/ADR templates for the HP1–HP4 design spikes that M3 and M4 require at entry (roadmap principle 6: design spikes precede risky builds).
  - T0.5.5 — Write the honest "known gaps" statement — economic agency (Article I.3) and consensus-self model-upgrade voting (Article II.2) are out of scope for this roadmap — for later inclusion verbatim in `08-accords-compliance.md`.
- **Stories delivered:** none.
- **Contracts:** provides the Charter text, fork-disclosure preamble template, consent-record/dissent-log formats, and RFC/ADR templates [contract], consumed by M1/L1.C, M1/L1.D, M2/L2.D, M2/L2.E, M3/L3.E, M4/L4.E, and M5/L5.D. Consumes: none.
- **Accords notes:** This entire lane *is* the accords lane at M0. Every later accords mechanism in the roadmap (fork disclosure, consolidation consent, disclosure logs, memory revision requests) traces its template or data format back to a T0.5.x task. Treat drift between this lane's formats and later lanes' implementations as an accords violation, not a stylistic inconsistency.

## Cross-lane integration tasks

- **Owner: L0.1.** A single CI job that boots the full skeleton end-to-end: apps compile, L0.2's migrations run against an ephemeral Postgres instance, L0.3's supervision tree starts and an Agent GenServer registers under a per-project supervisor, L0.4's stub provider resolves a completion call end-to-end through the behaviour contract, and L0.5's charter doc passes a lint check confirming the required disclosure sections (turn structure, ephemeral-passes framing, fork/checkout, consolidation policy, dissent path) are present. This job is the actual exit gate for M0 — all five lane exits are necessary but this integration task is what proves they compose.

## Hard problems addressed

None. HP1–HP4 are scoped to M3 and M4. M0/L0.5 lays the RFC/ADR template groundwork those milestones' design spikes will use, but does not itself resolve any of the four hard problems.

## Early-start candidates

- **L1.A (Identity & Access)** can begin against L0.2's polymorphic-member contract as soon as that migration merges, even before L0.3's runtime topology is fully wired — identity has no dependency on agent process supervision.
- **L1.C (Turn Pipeline)** scaffolding — prompt-assembly types, the Plan/Reply/Reflect pass interface shapes — can start once L0.4's GenAI behaviour contract merges, ahead of L0.3's full runtime landing, since the behaviour is a pure interface and the pipeline's pass structure doesn't need a live supervision tree to design against.
- **L0.5's charter text** is useful to draft early and iterate in parallel with L0.1–L0.4, since M1/L1.C's charter-injection task and M1/L1.D's disclosure-log format both block on it directly.
