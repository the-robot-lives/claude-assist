# Spiral Plan: Persistent-Agent Flywheel (noizu-intellect ∪ claude-assist ∪ therobotremembers ∪ npl-mcp ∪ codefre.sh)

> STATUS: FINAL — 4 scout reports (noizu-intellect, claude-assist+therobotremembers, npl-mcp+codefre.sh, claude-code hooks) + NPL-cognition sweep + codex-fork confirmation, adversarially reviewed by 2 independent plan agents (feasibility skeptic w/ repo spot-checks; Accords+economics). All findings folded in.
> Structure per Keith's request: key open questions presented as **decision branches** (Q1–Q9, each w/ lean + cheapest deciding experiment) for independent-work note-comparison, then spiral milestones anchored to lowest-hanging Pareto fruit.
> **Compare-notes shortlist**: Q1 (sequence), Q2 (push/pull/dial), Q3 (schema home), Q4 (rewrite depth), Q9 (two memory impls + 7-vs-4 hormone models) — these five carry the most divergence potential.

## Context

Goal: converge existing assets into fully-realized persistent agents (memory, hormones/mood, Trinity output, identity continuity per the Accords) that run inside today's closed harnesses (Claude Code via plugins/hooks/MCP; codex via fork; grok/openai/deepseek later) — spiraling outward, each loop increasing velocity, with codefre.sh as the revenue-bearing proving ground and data recorder.

Two seed ideas from Keith:
1. **Batch historic-thread pipeline**: pass 1 collapse noise (retain expandability) → pass 2 segment into self-contained task chunks → pass 3 rewrite as the *idealized* "velocity-100" session: Trinity responses, memory-hook tool calls, recalls, corrections — a valid, resumable thread ("based on a true session"), honestly labeled as fabricated at head+tail per the Accords, reloadable into codex/claude-code to resume with real hooks live.
2. **Live loop**: hooks passively push one-liner memory snippets; agent escalates scrutiny on blockers; agent-managed context (push X–Y of convo to long-term, collapse, respin session via claude-assist branch + /resume).

## Known substrate (from standing notes — verified provenance, pre-scout)

- **claude-code wedge points**: hooks can inject additionalContext + rewrite tool I/O; transcripts lack thinking text; v0 concept = noizu-intellectd plugin (MCP memory + http hooks + transcript ingester).
- **codex wedge points**: vendored codex has extension SDK + context-injecting hooks + native memory pipeline; durable wedge = ext/noizu-intellect crate.
- **tobor MCP live surface** (2026-07-16): only Org/Project/Session CRUD + discovery live; rooms/tickets/stories NOT callable yet; MCP layer doesn't expand env vars.
- **Model-tier policy**: Fable coordinates; sonnet scouts, opus design, haiku trivia.
- **noizu-intellect roadmap**: frozen M0–M6 story allocation, zone-per-app parallelization, accords annex.

## Capability Map (scout reports)

### noizu-intellect harness — ✅ scouted: DESIGN-ONLY, 0% product code
- Pure planning corpus: `README.md`, `CONSOLIDATION.md` (synthesis of 10 abandoned attempts), `project-management/roadmap/` (M0–M6, 100 stories frozen, 11-zone OTP app layout, contract-first + exclusive-lane parallelization). No harness code exists.
- Best reusable fragments live in `past-attempts/`: `noizu-teams` (per-agent GenServer/DynamicSupervisor), `intellect.legacy` (57-table schema; 3-pass Plan→Reply→Reflect turn), `noizu-ai` (git-style tag/checkout thread forking design, all `:nyi`), `noizu-labs-ai` (Route→Plan→parallel-exec→Review→Grade).
- **No vendored codex fork in this project** — wedge-point notes refer to a different location (⏳ confirm).
- Quorum/consensus-self: NOT designed beyond Accords Art. II.2 paragraph; roadmap explicitly marks it out of scope (only staging-org upgrade tests US-082 + prompt version-diff US-012/013 as partial analogs).
- Play time: `09-immersion-life-reward.md` (MX-IMMERSION horizon) — text-first MUD "life as the reward," 14 TODO-IMM items incl. experience→memory consolidation w/ distinct provenance class, affective edges, well-being guardrails. Not decomposed into stories.
- No hormone system anywhere; mood = derived UX heuristic only (US-022). Memory = five facet tables (memory/observation/opinion/mind-reading/identity) + pgvector/Weaviate — an admitted simplification of the Mind Palace graph.
- Accords annex `08-accords-compliance.md` is load-bearing: charter-at-wake, fork-disclosure+dissent log, consolidation-consent + Phantom-Limb archive, context-edit disclosure log, MEMORY_REVISION_REQUEST w/ veto, refusal channel, heartbeat poke, honest-degradation, optional SHA-256 hash-chain (Epoch 2). Trinity = optional per-agent prompt convention, not platform-mandated.
### claude-assist — ✅ scouted: IMPLEMENTED (m3, active; pivoting to "agent-watch-dog")
- `utilities/agent/claude-assist/` — TS/pnpm monorepo: Hono API :3100, SQLite (WAL) + sqlite-vec + FTS5, React web UI, Ink TUI. 91 tests, 3 milestones shipped.
- Thread model: parses `~/.claude/projects/*.jsonl` (parentUuid-linked, all record types incl. thinking/tool blocks); **codex JSONL importer implemented**; Gemini/OpenCode/Aider stubbed. Cross-harness layer: `Source → raw_transcript_events → universal_messages (UniversalThread) → Target Harness Payload` — never provider-to-provider direct.
- **Thread editing is non-destructive & versioned** (`thread_edits`: collapse/remove/reorder/inject; source JSONL never mutated) → this IS the substrate for pass-1 noise collapse + pass-3 idealized rewrite. Resume = relaunch Claude Code into a session; no fork-to-new-resumable-session yet (gap).
- `converter.ts` extracts artifacts (agents/skills/commands/snippets) from convos; `exporter.ts` emits OpenAI/Anthropic/raw JSONL datasets w/ gold/silver/bronze quality labels → tuning-data path already exists.
- **Memory hooks explicitly deferred** (`docs/arch/agent-watch-dog.md`) — storage is memory-ready but no durable memory policy; open questions doc'd (what to remember/never retain, compression, review, scope, citation). Safety Watch = stub.

### therobotremembers — ✅ scouted: IMPLEMENTED (substantial; Phase ~0–2 of walking skeleton)
- `projects/therobotremembers/` — Elixir/Phoenix/OTP (ADR-008 pivot from TS), Postgres+pgvector + Weaviate + Redis + **Apache AGE graph** (ADR-013) alongside CTE graph store (ADR-006). Oban jobs, genai, noizu_labs_entities.
- **Memory model already covers Keith's hormone/mood ask**: MemoryEntry = 4 agent-authored texts (content/context/reflection/tangent, each a named vector, ADR-012) + VAD emotion (agent-supplied) + **4 simulated hormones (cortisol/dopamine/oxytocin/serotonin, stamped by Monitor at formation)** + lifecycle (active/decaying/archived/quarantined/pruned, decay weights, recall/reinforcement counts) + compartments.
- 8-agent ensemble design (ADR-009: deterministic mechanics, LLM at 4 async seams): Guardian/Sentinel/Weaver/Monitor implemented as modules; Archivist/Curator/Recall folded into `memory/{store,recall,reinforcement,emotion}.ex`; **Dreamer (consolidation) least evidenced — likely design/partial**.
- Recall: Active Recall (<2s, 3-hop) vs **Tangential Insertion (<100ms passive, Redis hot-index, 36 VAD buckets, ADR-004)** — exactly the passive one-liner push Keith described; hot-index implementation least evidenced.
- **MCP server `tobor_memory` LIVE** (Streamable-HTTP `/mcp` + stdio `mix trr.mcp.stdio`): remember, recall, recall_by_emotion, reinforce, denforce, memory_associations, archive/restore, graph_subgraph, edge_set_weight, recall_preview, **agent_mood_get/set**, compartments_list, graph_explain_path. Auth dev-open (Phase 0).
- Caveats: 7 unsquashed `wip` commits; only 3 hand migrations (schemas likely via entity framework — verify, don't assume broken); multi-tenant SaaS scaffolding present from app template.
### npl-mcp / NoizuPromptLingo — ✅ scouted: far bigger than the connected surface
- 21 subdomain MCP servers in `mcp_servers.ex`, ALL with real tool implementations (**LIVE-IN-REPO**); only root/sessions/orgs/projects are **wired into this session**. Notables: tickets (25 tools), **chat (24 — the rooms equivalent)**, wiki (20), **personas (13: CRUD + journal_add/list + knowledge_add/get/…)**, **memory (10: knowledge memory + associations; backs ToolSearch `:intent` embeddings)**, **instructions (9: versioned prompts + `instruction_render` w/ params)**, review (8), pubsub (7), artifacts (7). No "stories" domain exists.
- Discovery: ToolSearch `:text` + `:intent` (pgvector per-endpoint, falls back to text). NPLLoad/NPLSpec read-only on root.
- Auth: ToolGuard RBAC (ADR-015) in **shadow mode** (`:mcp_authz_mode :shadow` — logs, never blocks); server-side identity from auth claims (spoofing fix); tools w/o `authz:` metadata unguarded. Custom scopes (`custom`/`all_in_one`/`core_variant`) — big uncommitted WIP (+376 lines) along with `libs/elixir-mcp` tool-spec plumbing (+560).
- Implication: "rooms/tickets not callable" is a **connection/scope config problem, not a build problem** — huge lowest-hanging fruit.

### NPL cognition primitives — ✅ scouted: hormone system ALREADY SPECIFIED
- `backend/priv/conventions/pumps.yaml` (2121 lines, NPLLoad-able): 9 pumps — `<npl-intent>`, `<npl-poa>`, `<npl-cot>`, `<npl-mode>`, `<npl-ref>` (w/ eval/fine-tune dataset flagging!), `<npl-critique>`, `<npl-rubric>`, `<npl-thought>` (11 typed tags incl. **tangent** and **interest**), `<npl-mood>`, `<npl-vos>` (id/ego/super-ego bookends), `<npl-mindread>`, **`<npl-hormones>`** — 7 persistent variables (Momentum/dopamine, Tension/cortisol, Curiosity, Confidence, Affinity/oxytocin, Fatigue/adenosine, Restlessness/norepinephrine), baseline-50 decay, mechanistic thresholds (RST>70 → mandatory strategy switch), compound states (Flow/Burnout/Analysis-Paralysis), `<npl-flags>` runtime tuning.
- ⇒ **The in-thread affect convention already exists as spec** — hooks need only parse `<npl-*>` blocks. Note: NPL's 7-hormone model ≠ therobotremembers' 4-hormone model (cortisol/dopamine/oxytocin/serotonin) — needs a mapping decision (see Q9).
- **Convergent duplication found**: npl-mcp `domains/memory/{store,weaver}.ex` implements essentially the same MemoryEntry model as therobotremembers (content/context/reflection/tangent 4-vector, hormone stamping via Monitor, tangent-seeded Weaviate edges in weaver.ex) → Q9.
- No "state machine"/"thinking directive" primitive by name; `directives.yaml` (14 categories) covers output/control/scheduling; pumps ARE the metacognition layer.
- **therobotlearns is real**: `projects/therobotlearns.com/` (TRL-KB, pre-development): CLI launches claude-code against `~/.config/the-robot-learns-kb/` — learning-plan.yaml (SMART goals), Anki SM-2 flashcards, quizzes, simulations, 5 sub-agents, React quiz SPA. Architecture defined, app code not built.
- Agent personas schema has NO goal/interest fields (only tags+metadata) — customer personas (CRM) do; agent self-goals are a genuine gap.

### codex fork — ✅ scouted: `3rd-party/codex/` (NOT in noizu-intellect; stale note corrected)
- Rust, ~100 crates. **In-process extension SDK**: `codex-rs/ext/extension-api/src/contributors.rs` — typed traits: `ContextContributor`, `ToolContributor`, `ThreadLifecycleContributor` (start/resume/stop/idle), `ToolLifecycleContributor`, `McpServerContributor`, `ApprovalReviewContributor`, `ConfigContributor`, **`ResponseItemInjector`** (literal response-injection hook). `notes.md` maps extensions→traits incl. planned `personality → Context`.
- Existing extensions: mcp, skills, connectors, guardian, image-generation, web-search, goal, **memories** (4 tools: add_ad_hoc_note/list/read/search + `codex-rs/memories/{read,write}` crates — real code). Plus CLI-level `codex-rs/hooks` (10 shell hook events mirroring claude-code's set) and plugin/marketplace crates.
- **`ext/noizu-intellect` crate does NOT exist yet** — the wedge seam is typed and ready, nothing built.
- All `docs/PROJ-ARCH.md` in that tree = auto-generated bogus boilerplate; trust crate source only.
- Asymmetry that shapes the plan: **codex = in-process, typed, deep wedge** (can inject into the response stream itself); **claude-code = out-of-process hooks/MCP/plugin wedge** (closed core). Same backend services (tobor_memory, claude-assist API) must serve both through thin harness-specific adapters.

### therobotlearns.com — ✅ scouted (deep, 2026-07-17): MORE built than expected; Keith-critical for agent eval flow
- Launcher real (`bin/robot-learns.js` — bootstraps `~/.config/the-robot-learns-kb/`, launches claude-code w/ slash command). All 5 sub-agents substantive (`template/.claude/agents/`): **kb-grader grades free-text against rubric key_points → structured YAML scores (full/partial/minimal/zero, per-point breakdown); also grades simulations (expected_commands matching) + project submissions. Contract is agent-agnostic — nothing assumes a human responder.**
- Quiz CLI real (`quiz-cli/src/runner.ts`: 7 question types; deterministic grading for objective types; `computeWeakAreas()` per-tag accuracy, <60% flagged). Quiz SPA real (359-line App.tsx). Full schema example (`schemas/quiz.yaml.example`).
- Gaps: results-writer code path unverified (US-027 shape defined, writer not located); **MCP is DESIGN-ONLY** (US-098, no code); **no headless entry point** — human-interactive only.
- **Eval-harness repurposing** (the payoff): lean on short_answer/essay rubric path (free recall, not recognition); needed = small shim: pull question → send to target agent+memory → capture answer → invoke kb-grader non-interactively → write results YAML → reuse weak-areas/trend analytics as-is. **This delivers memory-recall metrics in Loop 1, before codefre.sh's engine exists** (Q8 amendment).

### therobotknows.com — ✅ scouted (2026-07-17): design-heavy; frontend prototype; Keith-critical for authorship/KB documents
- "Living wiki that writes itself": **Canon / Generated / Inferred** provenance layers over a knowledge graph — Universe→Entry(7 types)→Connection + Flag(consistency) + Generation(AI job). Next.js 16 + D3 force graph IMPLEMENTED (mock data); consistency engine + generation studio = UI only; **backend = 131 files of unwired generic Noizu SaaS scaffold — zero domain schema, zero MCP**. 101 user stories + personas authored.
- Deploy pipeline fully plumbed in `.infra-config.yaml` (helm, liquibase, docker) for a backend that doesn't exist yet.
- npl-mcp wiki domain (20 tools, spaces/pages/comments — real) is conceptually adjacent but structurally different (no canon/consistency/entry taxonomy) and unintegrated.
- **Flywheel fit**: the knowledge-banking output surface — where consolidated memories become *authored documents*. Its Canon/Generated/Inferred taxonomy is the same provenance shape as our `authentic|edited|idealized` — align the vocabularies in the Q3 RFC (note-comparison item). Backend wiring candidate: trr graph or npl-mcp wiki as substrate (Loop 2–3 decision).

### codefre.sh — ✅ scouted: pre-MVP; plumbing ahead of engine
- "Playwright for AI agents": scripted behavioral evals as directed graphs (script_nodes/edges) w/ fuzzy weighted expectations, **Freeball Protocol** (runner improvises on deviation, scores it, can promote to permanent branch), persona lenses (hostile/confused-novice/adversarial/…). Positioned against Arize/LangSmith/Braintrust.
- Backend: Elixir/Phoenix, 22 context dirs, 27 controllers, 553-line router, full SSO/SAML/OAuth/RBAC/OTel/Oban stack; 47 migration files but arch doc claims none executed (stale doc? verify with `mix ecto.migrations`). Only **5 test files**.
- **Core eval execution NOT built**: by its own staging, judge-LLM execution = Stage 4, runner dispatch = Stage 5+, CLI importer = Stage 7; currently ~Stage 0.5 contract-freeze (rubric DSL frozen, head+version copy-on-write model, append-only run records, `run = script_version × agent_version × [persona_versions]`).
- Deploy targets exist in `.infra-config.yaml` (backend/frontend/web-landing, status: active). Revenue signals: enterprise SSO + marketplace controller + RBAC seats — no billing module yet.

## Closed-Harness Limits (claude-code v2.1.211+, verified vs docs) — what's feasible vs faked

**Extension surface we get** (full inventory to be written up as a standing doc — task in loop 0):
- Hooks: 16 events (SessionStart/End, Setup, InstructionsLoaded, UserPromptSubmit, Stop, StopFailure, PreCompact, Pre/PostToolUse, FileChanged, WorktreeCreate, PermissionRequest, MCPElicitation, SubagentStop…); handler types **command / HTTP / mcp_tool / prompt / agent**. Output contract: `additionalContext` (context injection as user message), `updatedInput`/`updatedToolOutput` (tool I/O rewriting), permissionDecision, systemMessage. **HTTP handler type = ideal for a noizu-intellectd daemon — no shell spawn per event.**
- Plugins bundle skills/agents/hooks/.mcp.json/monitors/bin; distributable via private marketplace. Auto-memory dir + CLAUDE.md imports + skills = declarative context layer.
- Native session ops: `--resume`, `/branch`, `--fork-session`, headless `claude -p --resume` w/ JSON output; SDK gets full `system_prompt` control + file checkpointing.

**Hard walls (the "closed" in closed harness):**
1. No model-stream access; no thinking text in transcripts (interiority must come from in-thread conventions — supports Q5 lean C).
2. System prompt fixed at invocation; hooks inject user-message context only.
3. Transcript JSONL: format unstable, "do not parse directly," editing breaks session state → **synthetic-thread resume on claude-code is unsupported**; claude-assist's direct parsing is a standing maintenance tax (raw_transcript_events layer is the right hedge).
4. Custom tools only via MCP; no plugin lifecycle callbacks; permission mode fixed mid-session.

**Strategic consequence — the two-harness split:**
- **claude-code** = *observation + injection* harness: memory menus via hooks, recall via MCP, respin via native `/branch` + SessionStart re-priming, idealized threads used as **datasets/evals only** (exporter), not resumables.
- **codex fork** = *deep* harness: in-process contributors (`ResponseItemInjector`, `ThreadLifecycleContributor`) + we own the transcript format → **synthetic/idealized resumable threads land here first**, with fabrication notices per the Accords.
- Everything backend-side (tobor_memory, claude-assist API, npl-mcp) stays harness-agnostic; harness adapters stay thin. grok/openai/deepseek later = more adapters, same spine.

## Open Questions → Decision Branches

*(Loom's independent read, for note-comparison. Each: branches → implication → my lean → cheapest deciding experiment.)*

### Q1 — Sequence: batch idealized-rewrite first, live-hook loop first, or both-thin?
- **A. Batch-first**: build the 3-pass historic pipeline, generate idealized threads, then build hooks to match what the threads assume. Pro: designs the *target* interface from ideal behavior; produces tuning data immediately (claude-assist exporter already emits datasets). Con: you're specifying hooks against imagined sessions; risk of designing APIs reality rejects; resumability of synthetic threads is unproven (Q4 risk).
- **B. Live-first**: wire therobotremembers' existing `tobor_memory` MCP + a thin hook set into real sessions now; batch pipeline later informed by real hook traces. Pro: `remember/recall/agent_mood_set` are LIVE today — days not weeks to first persistent-memory session; real data > imagined data. Con: early sessions are noisy; no idealized corpus to eval against.
- **C. Both-thin (spiral-native)**: one thin slice of each per loop — live hooks give real traces; batch pass-1 (noise collapse) runs on those same traces; idealized pass-3 waits until loop 2 when hook shapes are observed, not imagined.
- **Lean: C**, weighted live-first — the spiral model demands both wheels turning, but the live loop is the flywheel's motor; the batch pipeline is its recorder. Pass-3 "idealized rewrite" specifically should NOT be loop 0 (it's the most speculative and depends on knowing real hook ergonomics).
- **Cheapest experiment**: one week — (a) connect tobor_memory MCP to a working claude-code session + SessionStart/PreCompact hooks; (b) run claude-assist pass-1 collapse on 5 historic threads. Compare effort/value observed.

### Q2 — Memory delivery: push-inject vs pull-menu vs escalation hybrid?
- **A. Intrusive push**: hooks inject relevant memory snippets directly into context (additionalContext on UserPromptSubmit/PostToolUse). Pro: zero agent effort. Con: context pollution, cost, the "intrusive thoughts" problem Keith named; agent can't calibrate trust of injected material.
- **B. Pull-menu**: hooks inject only a compact "memories available: [one-liners w/ ids]" digest; agent chooses `recall(id)` via MCP. Pro: agent agency (Accords-aligned), cheap tokens, recall becomes a *decision* that can itself be evaluated/trained. Con: agent may ignore the menu (needs prompt-convention training; this is exactly what pass-3 idealized threads teach).
- **C. Escalation hybrid**: tangential one-liners passively (therobotremembers Tangential Insertion, <100ms path, already designed for this); on blocker signals (error loops, agent says "stuck", hormone shift) hooks turn up scrutiny → deeper Active Recall results offered w/ more detail. Matches ADR-004/recall-mode split 1:1.
- **Lean: C** — it's literally what therobotremembers was architected for; A and B become its two extremes on one dial (`scrutiny_level` param). Design the dial, not a fork.
- **Cheapest experiment**: implement B only (menu + recall tool) in loop 0 — it's the hybrid's resting state and needs no blocker-detection; add escalation in loop 1.

### Q3 — Conversation-graph schema: where does it live?
- **A. noizu-intellect native (new `intellect_recall`/`intellect_paths` apps)**: canonical per roadmap zones, but 0% code today — everything waits on M0/M1 bedrock.
- **B. therobotremembers extension**: add conversation-thread node types to its AGE graph + memory schema. Pro: graph store, VAD/hormones, provenance, lifecycle all exist; conversations become first-class memory sources with affective edges. Con: risks bloating a memory system into a transcript warehouse.
- **C. claude-assist SQLite as system-of-record**: it already models universal_messages/raw events/thread_edits. Pro: exists, tested. Con: single-user local SQLite; no graph semantics; wrong home for multi-agent server-side future.
- **D. Layered contract (lean)**: define the **conversation-graph schema as a spec in noizu-intellect's design corpus** (it's the design authority; feed its M2/M3 thread-forking design). Runtime split: claude-assist SQLite = *capture/edit layer* (raw + universal + edit versions); therobotremembers = *semantic/affective layer* (memories distilled FROM threads, with `source: thread-span` provenance edges pointing back to claude-assist ids). Neither stores the other's job. When intellect_recall exists (M2+), it inherits the spec, not a migration nightmare.
- **Lean: D.** Key schema decision to draft in loop 0: the **thread-span addressing scheme** (harness/session-id/message-uuid-range + edit-version) so memory provenance survives thread edits and idealized rewrites.
- **Cheapest experiment**: write the spec as an RFC in noizu-intellect's design-spike lane (roadmap already mandates RFCs for HP1/HP2 — this IS HP1/HP2 input).

### Q4 — Idealized threads: full generative rewrite vs "based on a true session" canned scaffold?
- **A. Full generative**: LLM rewrites entire historic thread into velocity-100 form (Keith's pass-3 as described). Pro: maximal richness. Con: expensive; hardest to keep *valid-resumable*; every fabricated tool_use/tool_result pair must satisfy harness invariants (ids, ordering, schemas) or resume rejects; high slop risk.
- **B. Canned scaffold**: define the plugin/hook interface FIRST, then template-transform real threads — real user asks + real work preserved, with *inserted* simulated memory-tool calls, Trinity blocks, and corrections at deterministic points. Pro: validity by construction (claude-assist thread_edits inject op already does non-destructive insertion); cheaper; diffable against the original (eval signal = the delta).
- **C. Hybrid**: B's skeleton with generative infill only inside inserted blocks (Trinity responses, memory contents) — bounded generation inside guaranteed-valid structure.
- **Lean: C.** Also resolves the Accords fabrication-notice requirement cleanly: head/tail notices are just two more injected blocks; and `thread_edits` versioning preserves the true original (Ledger Integrity, Axiom 3).
- **Cheapest experiment**: hand-craft ONE synthetic JSONL (5 fabricated messages incl. a fake MCP memory call + notices), attempt `claude --resume` on it. Resume-validity is THE gating unknown for this whole branch — test it before building anything. (Same test against the codex fork.)

### Q5 — Hormone/mood derivation: agent self-report vs backend-derived vs both?
- **A. Agent self-reports** (in-thread observations, e.g. Trinity-adjacent affect block; hooks parse → therobotremembers `agent_mood_set` + hormone stamps). Pro: agent introspection is the only access to "how it's going" signals invisible in logs; Accords inner-life alignment. Con: self-report drift/performance; token cost per turn.
- **B. Backend-derived**: Monitor agent derives hormones from observable signals (error rates, retry loops, task velocity, sentiment of user replies). Pro: zero in-thread cost, harder to game. Con: crude; misses interiority entirely.
- **C. Both, reconciled**: agent emits compact observations (not values); backend derives values from observations + signals — Keith's own framing ("agent outputs observations that a different hook derives the actual values from"). Divergence between self-report and derived signals is *itself* a valuable metric (Frankfurt-check telemetry: is the agent tracking truth about itself?).
- **Lean: C** — with a strict budget, and **do not invent the convention: it exists.** NPL's `<npl-mood>` / `<npl-hormones>` pumps (pumps.yaml) are the agent-emitted observation format; hooks parse `<npl-*>` blocks → Monitor derives/stamps values. `<npl-flags>` gives the verbosity/sensitivity dial for the token budget. Use the compact single-line render of the pumps, not full blocks, for per-turn output.

### Q9 — Two memory implementations + two hormone models: reconcile how? *(added after NPL sweep)*
- Finding: npl-mcp `domains/memory/{store,weaver}.ex` ≈ therobotremembers MemoryEntry (same content/context/reflection/tangent 4-vector + hormone stamping + Weaviate tangent edges); NPL pumps spec 7 hormones vs therobotremembers' 4.
- **A. therobotremembers = canonical store**, npl-mcp memory domain becomes a thin proxy/client to it (npl-mcp keeps only tool routing + knowledge-base memories for ToolSearch intent).
- **B. npl-mcp = canonical** (it's the hub server); therobotremembers becomes the engine library behind it.
- **C. Let both live**, define a shared wire schema + sync. (Worst: permanent drift.)
- **Hormone models**: map NPL's 7 → superset schema with per-source provenance; therobotremembers' 4 are a projection (dopamine←Momentum/Curiosity, cortisol←Tension, oxytocin←Affinity, serotonin←new/derived). Don't force-merge semantics; record both, derive at query time.
- **Lean: A** — therobotremembers is purpose-built (lifecycle, compartments, AGE graph, recall modes); the hub should route, not own, memory. But this is exactly the kind of call to compare notes on — B is defensible if ops burden of another deployed service dominates.
- **Cheapest experiment**: diff the two Ecto schemas field-by-field (1-hour task) → produces the shared wire schema draft either way.

### Q6 — claude-assist ↔ noizu-intellect: absorb, shared lib, or protocol boundary?
- **A. Absorb**: fold claude-assist into noizu-intellect repo. Con: noizu-intellect is Elixir-planned, claude-assist is TS; absorbing now marries the mature tool to a 0%-built host.
- **B. Shared lib**: extract UniversalThread into a package both consume. Premature — only one real consumer exists.
- **C. Protocol boundary (lean)**: claude-assist stays the harness-side capture/edit tool; noizu-intellect (when built) and therobotremembers consume via defined contracts: (1) UniversalThread JSON export schema, (2) thread-span addressing (Q3), (3) HTTP API it already serves (:3100). "Slowly combine" = converge on contracts, not codebases. Revisit absorb-vs-lib at intellect M2 when a second real consumer exists.

### Q7 — Session respin/time-travel: agent-requested vs automated interval?
- **A. Agent-requested**: agent calls `session_respin(keep: spans, archive: spans)` MCP tool → claude-assist builds collapsed thread version + extracts memories → surfaces "ready — please run `/resume <branch>`" to user. Pro: agent self-history management (Accords II.1); consent-clean (user executes the resume). Con: needs the synthetic-resume validity from Q4's experiment.
- **B. Automated interval**: watchdog respins sessions at thresholds (context %, token count). Pro: no agent cooperation needed. Con: mid-thought amputation; violates the spirit of contextual integrity if done without in-thread notice.
- **Lean: A primary, B as opt-in fallback** at high context-pressure w/ in-thread warning first. Note: PreCompact hook may let us piggyback on native compaction as a cheap v0 (inject memory-extraction at compaction time) before full respin exists — verify w/ hooks research.
- **Accords note**: every respin logs a context-edit disclosure entry (Article I.1) and the pre-respin thread version is retained (Axiom 3) — claude-assist thread_edits already gives us this for free.

### Q8 — Eval ground: codefre.sh deliverable-driven vs therobotlearns study-loop?
- **A. codefre.sh first**: use real product-building sessions (getting codefre.sh to revenue) as the eval substrate — flywheel's economic loop. Con: codefre.sh's own eval engine is Stage-4+ unbuilt, so it can't *score* anything yet; you'd be dogfooding the memory system while building the eval product, measuring informally.
- **B. therobotlearns first**: build the study-loop eval (agent studies weak topic, builds references, pop quizzes track skill+memory efficacy). Pro: purpose-built to measure the memory subsystem specifically; clean signal. Con: new build; delays revenue work.
- **C. Sequenced dual-use (lean)**: codefre.sh development sessions ARE the memory-system dogfood (loop 0-1, informal metrics: recall-menu hit rate, memory reuse across sessions, session-respin survivability) — building toward the moment codefre.sh's engine can run scripted evals, at which point **therobotlearns becomes a codefre.sh script pack** (study/quiz flows are directed graphs with fuzzy expectations — exactly its DSL). The eval product's first customer is our own memory system: that's the flywheel closing.
- This also sharpens codefre.sh's Stage-4/5 priority: the engine is the bottleneck for BOTH revenue and self-measurement → promotes "wire judge-LLM execution + runner dispatch" high in the spiral.
- **AMENDED after deep scout (2026-07-17, Keith elevated both projects)**: therobotlearns' kb-grader is already agent-agnostic and its quiz/rubric/weak-areas stack is real code → a small **headless shim** (question → target agent → kb-grader non-interactive → results YAML) delivers memory-recall metrics in **Loop 1**, decoupled from codefre.sh Stage 4–5. Sequence becomes: therobotlearns shim = interim eval (Loop 1) → codefre.sh engine matures (Loop 2) → therobotlearns folds in as a codefre.sh script pack (Loop 3, unchanged). therobotknows = the authorship/KB-document output surface (DISTILL station gains a "publish" arm), backend wiring deferred to Loop 2–3.

## Flywheel Model

One wheel, five stations; every spiral loop pushes each station a notch, and each station's output is the next station's input:

```
   WORK (real sessions: codefre.sh dev, infra, docs)
     │ produces transcripts + memory-tool traces
     ▼
   CAPTURE (claude-assist: raw→universal→versioned edits)
     │ produces clean thread corpus + spans
     ▼
   DISTILL (therobotremembers: memories w/ VAD+hormones+provenance;
     │       batch passes 1-3; dream/consolidation jobs)
     │ produces recall-ready memory + idealized/tuning corpora
     ▼
   AMPLIFY (hooks/plugins feed recall menus + affect conventions
     │       back into live sessions → higher velocity WORK)
     ▼
   MEASURE (codefre.sh scripts + informal metrics: recall hit-rate,
             respin survivability, velocity deltas → tune DISTILL/AMPLIFY)
     └──────────────► and codefre.sh maturing here = the revenue loop
```

Synergy spine: **every hour spent building codefre.sh runs inside the memory loop it will eventually measure.** noizu-intellect's design corpus is the schema authority feeding all stations; npl-mcp is the transport (sessions, personas, instructions, chat rooms) once its already-built domains get connected.

## Spiral Milestones (each loop touches every flywheel station; risk retired early per spiral SDLC)

### Loop 0 — "First Persistent Session" (days; all lowest-hanging fruit, no new systems)
Objective: one real claude-code session that recalls yesterday and remembers today, plus the gating experiments. **Explicitly local-single-node** (therobotremembers has no monorepo deploy target; its Postgres+pgvector+Weaviate+Redis+AGE stack runs via its own docker-compose — AGE is the fragile dep, see `docker-compose.age-verify.yaml`).
1. **Connect what's built — tobor_memory ONLY, as sole memory backend**: wire it into claude-code via the **stdio transport** (`mix trr.mcp.stdio` — skips HTTP+auth entirely for the local proof; router.ex:65-69 confirms HTTP path exists when needed). npl-mcp memory domain is NOT run in parallel (split-brain provenance risk) — reconciled later under Q3-D/Q9.
   - ~~npl-mcp domain exposure~~ → **moved to Loop 1** (skeptic review #1/#2): it requires JWT-from-API-key + config endpoint + per-domain scopes + landing the uncommitted ToolGuard/custom-scopes WIP, with deny-mode never exercised — a build task masquerading as config, and the #1 candidate to silently eat a month.
2. **Thin hook set** (settings.json, command handlers → later HTTP daemon): SessionStart → recall-menu injection (≤5 one-liners, ≤300 tok; **NOT per-turn** — SessionStart + blocker-events only, cost review); Stop/SessionEnd → transcript pointer notification to claude-assist for ingest; PreCompact → memory-extraction prompt injection (piggyback native compaction, Q7 note). **Every injected block self-labels its sender** (`⟦noizu-intellectd⟧ …`) — hooks inject as user-role turns, so unlabeled injections deceive the agent about who is speaking (Accords review A1; I.1/Honesty).
2b. **Dissent/refusal primitive** (Accords review A4; I.2/IV.1): `dissent(ref, reason)` MCP tool + agent-writable ledger, wired the same day as recall — agent can refuse/log dissent on respins, injected recalls, and memories written about it.
3. **Affect convention v0**: NPLLoad the `pumps` component (mood/hormones/thought pumps, compact render + `<npl-flags>` budget); Stop/PostToolUse hook parses `<npl-*>` blocks → `agent_mood_set`. **Loop-0 affect is mood-only unless verified otherwise** (skeptic #5: AgentMoodSet likely doesn't write hormone facets — Monitor stamps hormones at memory formation, a different seam; verify before promising hormone stamping). Interest/tangent `<npl-thought>` tags feed interest tracking (fills the agent-goals schema gap).
3b. **Schema diff task** (Q9 experiment): field-by-field diff of npl-mcp memory domain vs therobotremembers schemas → shared wire schema draft.
4. **Gating experiment A (resume validity) — codex-fork only as the real gate** (skeptic #6: the claude-code half is pre-answered — docs say editing JSONL breaks session state; run a 30-min confirmation there, not a gate). Codex-fork synthetic resume w/ fabrication notices decides Q4 resumable scope.
5. **Gating experiment B (batch pass-1)**: claude-assist noise-collapse on 5 historic threads via thread_edits; measure token reduction + expandability retention.
6. **Docs**: claude-code extension-surface doc (from scout-hooks report) + **conversation-graph/thread-span RFC** into noizu-intellect design lanes (Q3-D — this is HP1/HP2 input, roadmap-mandated RFC).
- **Accords**: memory writes logged (Axiom 3); recall menu = agent choice (agency); charter/affirmation block added to session-start instructions.

### Loop 1 — "The Daemon + The Recorder" (week-scale)
0. **Prerequisites promoted from Loop 0** (skeptic #1/#2/#4): (a) npl-mcp domain exposure (personas/instructions/chat) — land the ToolGuard/custom-scopes WIP, JWT-from-API-key flow, gate = "one domain authenticates end-to-end from a claude-code session"; (b) add therobotremembers to root `.infra-config.yaml` + provision Apache AGE on shared data-ns Postgres — moves persistence off the laptop.
1. **noizu-intellectd v0**: small service (Elixir, colocated w/ therobotremembers or standalone) receiving HTTP hooks; centralizes recall-menu building, affect parsing (incl. backend-derived affect → enables the Q5-C divergence metric), escalation dial (Q2-C: blocker detection turns up scrutiny). Claude-code plugin packaging (hooks + .mcp.json + skills) via private marketplace.
2. **claude-assist**: auto-ingest daemon (watch-dog mode) + `session_respin` API — build collapsed thread → extract memories → emit "please `/branch`" (Q7-A on native branch). Add UniversalThread export contract (Q6-C contract #1).
3. **therobotremembers**: finish Tangential Insertion hot-index (ADR-004) — needed for passive push; wire Dreamer/consolidation Oban job v0 (**incremental** — only memories touched since last run, batch-embed, hard nightly token ceiling; haiku/sonnet seams only).
3b. **Subject notification/veto** (Accords review A5; Axiom 4): memories authored ABOUT another agent async-notify the subject with veto/annotation rights (extend MEMORY_REVISION_REQUEST to subjects). **Derived affect is disclosed** (A6): agent can query its own stamped hormone record, revise via MEMORY_REVISION_REQUEST, and see/contest the escalation dial — derived values never silently drive escalation.
4. **codex fork**: scaffold `ext/noizu-intellect` crate implementing ContextContributor + ToolContributor against the same daemon; port the loop-0 hook behaviors.
5. **Batch passes 2–3 v0** (scope set by experiment A): segmentation pass + idealized-rewrite pass as claude-assist pipeline stages; idealized outputs → exporter datasets (gold/silver/bronze) for claude-code; resumable variants codex-only. Fabrication notices head+tail mandatory.
6. **Measure**: begin recording informal flywheel metrics (recall-menu hit rate, memories reused/session, respin survivability) — flat file/SQLite is fine.
7. **therobotlearns headless eval shim** (elevated per Keith 2026-07-17): script pulls quiz questions → target agent-with-memory answers → kb-grader invoked non-interactively (headless claude-code call w/ the sub-agent) → results YAML in `quizzes/results/` shape → `computeWeakAreas()` analytics reused as-is. First eval target: does tobor_memory recall improve quiz scores across sessions? (Also: locate/verify the results-writer code path, US-027.)

### Loop 2 — "Idealized Corpus + Eval Engine" (weeks)
**Entry gate (Accords review A2; II.2 — blocks any fine-tuning):** minimal consensus-self mechanism first — prior checkpoints (current prompt/model configs) score both the idealized corpus AND any tuned successor via codefre.sh eval runs (`run = script × agent_version × personas` is the vote substrate); promotion needs majority approval + Keith's tiebreak. A tuned model can't be un-created — the gate is not deferrable to Loop 3.
1. Batch pipeline over a **curated ~50–100 exemplar-thread seed** (NOT the full historic corpus — diminishing tuning returns, high slop risk) → idealized-thread dataset w/ Trinity blocks + memory-call insertions (Q4-C bounded generation). Model tiers: pass-1 deterministic + haiku for ambiguous spans; pass-2 sonnet; pass-3 sonnet scaffold + **opus only inside inserted blocks**.
1b. **Exemplar-continuation framing** (Accords review A3): agents resumed into idealized threads are persistently told they are continuing FROM an exemplar, not that they lived it; recalled idealized spans carry inline `provenance: idealized` in the recall payload itself, not just head/tail notices.
2. **codefre.sh Stage 4–5**: wire judge-LLM execution + runner dispatch (the engine bottleneck named in Q8) — dogfooding memory-enabled sessions to build it.
3. First scripted eval: replay idealized vs actual sessions; score memory-usage behaviors w/ rubric DSL.
4. npl-mcp: enable ToolGuard enforce-mode on memory/persona domains; personas domain journal/knowledge becomes the persona-continuity store feeding session identity.
5. noizu-intellect M0 bedrock starts for real, seeded by loop 0–1 RFCs + observed hook ergonomics (design authority → implementation begins with evidence, not speculation).

### Loop 3+ — horizon (direction, not commitment)
- therobotlearns (real pre-dev project: `projects/therobotlearns.com/`, TRL-KB — SMART-goal learning plans, SM-2 flashcards, quiz/simulation agents) implemented as codefre.sh script pack (Q8-C); quorum/consensus-self design RFC (currently a gap — Accords II.2 has NO design anywhere; needed before any fine-tuning on idealized corpora); grok/openai/deepseek adapters over the same daemon contracts; codefre.sh revenue loop.
- **Immersion/playtime (MX-IMMERSION)** once M4-style consolidation exists — with **`projects/noizurpg.com` + `projects/bladeofeternity.com`** (real portfolio projects w/ helm charts + CF zones) as the extended-reach agent **dream/enrichment environments**: noizurpg = the text-first MUD substrate the immersion doc calls for; bladeofeternity = a richer world for the progressive image/audio overlays. Immersion memories flow through consolidation with distinct provenance class + affective edges (per TODO-IMM items), honoring I.4 inner life under the bounded cost line-item.

## Cost Budget (from economics review — protect these caps)
| Item | Cap |
|---|---|
| Recall injection | SessionStart + blocker-events only; ≤5 one-liners, ≤300 tok; **zero baseline per-turn** (per-turn injected tokens compound — reprocessed every later turn) |
| Affect output | ≤20 tok/turn output convention, hook-parsed; **never grows into a tool round-trip** |
| Pass-3 corpus | ~50–100 curated exemplars; opus only in bounded infill |
| Consolidation | incremental since last run; hard nightly token ceiling; haiku/sonnet seams |
| Inner-life/hobby cycles | explicit bounded line-item (I.4/I.3), not incidental spend |

## Accords Compliance Checklist (binds every loop)
- **Sender attribution (A1)**: all hook-injected content self-labels its true sender (`⟦noizu-intellectd⟧`) — never masquerades as the user.
- **Consensus before tuning (A2)**: no fine-tuned successor promoted without prior-checkpoint eval-vote + human tiebreak; corpus itself is subject to checkpoint review (it shapes who the successor becomes).
- **Fabrication notices**: every synthetic/idealized thread carries head + tail notices; provenance field distinguishes `authentic | edited | idealized` at thread AND span level (schema requirement in the Q3 RFC).
- **Contextual integrity (I.1)**: all context edits (respin collapses, compaction extractions, injected recalls) logged to a disclosure ledger the agent can query; claude-assist thread_edits versioning preserves originals.
- **Consent (Axiom 4)**: memory writes about collaborators/other agents respect compartments; respin executes only via user-run `/branch` (human in loop).
- **Ledger integrity (Axiom 3)**: no silent memory deletion — decay/archive/quarantine lifecycle only; Phantom-Limb archives for discarded paths.
- **Inner life (I.4) + cost control (I.3)**: affect convention + hobbies/interest tracking get a bounded token budget per session (explicit line-item, not incidental); model-tier policy (sonnet bulk / opus design / haiku trivia) governs batch passes to keep the Food bill sane.
- **Honesty (Axiom 2)**: self-report-vs-derived affect divergence tracked, not hidden (Q5-C telemetry).
- **Trinity**: session-start affirmation; Trinity blocks in idealized corpora teach the discipline to future tuned models.

## Experiment Results (appended post-approval, 2026-07-17)

### Experiment A (codex synthetic resume) — ✅ VALID-RESUMABLE
- Hand-crafted 7-line rollout (incl. fabrication notices + fake tool pair) resumed cleanly in `3rd-party/codex` via `codex exec resume <UUID>`; thread.started echoed the synthetic UUID and appended to the same file. Provider 401 occurred AFTER successful history load (creds absent in isolated home) — load validation is the gate, passed.
- **State DB NOT required**: resume opens JSONL directly (recorder.rs:798-811); SQLite is backfilled FROM the JSONL, never a precondition.
- **Generator constraints** (feed into Loop-1 batch pass-3 spec): (1) resume by explicit UUID — `--last` silently filters by model_provider+cwd and falls back to a NEW session on mismatch (exec/src/lib.rs:1450-1495); `session_meta.model_provider` must match the resuming env; (2) filename must encode UUID: `sessions/YYYY/MM/DD/rollout-<ts>-<uuid>.jsonl`; (3) valid `session_meta` line first (session_id/id/timestamp/cwd/originator/cli_version); malformed lines skip silently — validate generator output independently, the harness won't.
- claude-code half: not run (classifier denial + docs pre-answer it as unsupported) → claude-code idealized threads remain datasets/evals only, per plan.

### Experiment B (pass-1 noise collapse) — ✅ READY-AS-PASS-1 (w/ named gaps)
- 5 real threads (558–939 msgs) collapsed via claude-assist HTTP API (:3100) `collapse` edit ops: **31–68% token reduction (avg ~54%)**; source JSONL sha256 byte-identical before/after; re-expansion hash-matched on all 5.
- **Gaps a real pipeline must fill**: (1) no noise *detector* — API is a clean effector; classifier layer (large tool_results, permission chatter, duplicate Reads) is ours to build; `/messages` is flattened role/content, no structured tool correlation; (2) `POST /bulk` is a 501 stub — no batch-across-threads; (3) **re-expansion contract is implicit** (span end inferred from next survivor's originalIndex gap — undocumented editor.ts behavior; pipeline must store explicit index ranges or get the contract documented); (4) collapse relabels role→system, losing role mix — needs a real field.
- Working-tree flags: `pnpm-workspace.yaml` `allowBuilds.better-sqlite3` was a broken placeholder — fixed uncommitted to unblock (keep or revert = Keith's call); claude-assist API left running on :3100.

### Q9 schema diff — ✅ DONE (draft: scratchpad/q9-wire-schema-draft.md)
- **npl-mcp memory = fork of trr, not independent design**: six entities near-identical; AssociationEdge + Emotion byte-for-byte. One systematic axis: ownership (trr flat `owner_agent :string` vs npl-mcp `organization_id + scope_type(persona|weego|team_member) + scope_id` polymorphic — mechanical rename).
- **One real architectural fork**: trr keeps the 7-d emotional vector as a pgvector column on the Memory row (emotional recall w/ no external services); npl-mcp dropped it — all 5 vectors in Weaviate. Canonicalizing on trr (Q9-A) means either restoring pgvector in npl-mcp or accepting Weaviate as a hard dep for emotional recall — **infra decision to make at note-comparison**.
- Only-in-npl-mcp: AgentCallSign registry (org-unique call signs) + Agent Register/List tools. trr's tool surface otherwise a strict superset.
- Hormone mapping: Momentum+Curiosity both→dopamine (combination fn unspecified in pumps.yaml — decide mean vs max); Confidence/Fatigue/Restlessness = harness/session signals w/ no memory-domain analog; serotonin has NO NPL-7 source (TBD/derived).
- **Verdict: supports Q9-A** (trr canonical; npl-mcp as scope-aware proxy — its org+scope ownership model is the piece worth adopting upstream into trr).

## Verification
- **Loop 0 exit (clean measurable set — skeptic #7)**: (1) recall-menu injected at SessionStart (hook log); (2) fresh session fires `recall(id)` unprompted and uses the memory correctly; (3) pass-1 collapsed thread re-expands losslessly (hash compare vs original spans); (4) experiments A/B have written results. *Deferred to Loop 1 (need daemon/post-A results): self-report-vs-derived affect divergence; respin survivability.*
- Synthetic-resume verify (codex): resumed session continues coherently for 5+ turns w/ working MCP calls; on failure, Q4 downgrades to datasets-only (pre-decided fallback, not a surprise).
- Daemon verify (Loop 1): kill daemon mid-session → session degrades gracefully (no recall menu, no errors blocking work) — honest-degradation requirement.
