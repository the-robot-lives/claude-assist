---
id: M2
name: Conversational Workspace
sequence: 2
depends_on: [M1]
lanes: 6
stories: [US-004, US-005, US-009, US-010, US-022, US-031, US-032, US-034, US-028, US-029, US-030, US-033, US-035, US-038, US-016, US-017, US-068, US-069, US-075, US-076, US-101]
hard_problems: []
---

# M2 — Conversational Workspace

M2 turns M1's API-only substrate into a product humans open in a browser and use daily: onboarding with templated agents, a live streaming chat surface, confidence-based routing sophistication beyond a bare `@slug`, memory inspection and search, and provider administration. When M2 exits, a team can actually run single-path multi-agent conversations end to end — sign up, staff a project with templated agents, talk to them in channels with `@everyone` pickup and side-channels, watch replies stream live, catch up via digest after an absence, and inspect or correct what an agent remembers — all without a single forked path yet.

## Entry criteria

- All M1 lane exits merged: identity/access (L1.A), agent lifecycle (L1.B), turn pipeline with charter injection and refusal channel (L1.C), cognition store with disclosure log and heartbeat (L1.D), channels core with audience-confidence and versioning (L1.E).
- M1's cross-lane integration smoke test (human posts `@mention` → agent turn → cognition write with disclosure) green.
- L0.5's Agent Charter and consent/dissent-log format remain the single source of truth for every disclosure this milestone's lanes emit — no lane redefines its own format.

## Exit criteria

- A new user can sign up, complete the org/project wizard, instantiate agents from a template gallery, take a guided accessibility-first tour of parallel-path execution, set up a profile, and switch between multiple org memberships — L2.A.
- A channel renders live: streaming pass-stage indicators and token-by-token replies, agent mood/status at a glance, threaded replies, and reactions/pins — L2.B.
- `@everyone` broadcasts get independent confidence-based pickup, channel-level thresholds are tunable, agents can open private side-channels, read receipts and unread counts track correctly, and a decisions-only notification mode exists — L2.C.
- Prompt assembly extends to tiered summarization and recursive threaded-context reconstruction, every summarization pass discloses itself, and a significance-ordered, accessible digest is available after an absence — L2.D [accords].
- Agent designers and compliance reviewers can inspect, edit, and prune cognition records with disclosure; long conversations distill into synthetic long-term memory; semantic vector search works over that memory — L2.E [accords].
- An admin can register LLM providers with encrypted credentials and define model tiers with ranked fallback — L2.F.
- A realtime voice front-tier session can attach to a channel and relay its rolling transcript + workspace deltas through the delegator pipe to a stronger drafting tier, which returns redline proposal artifacts carrying construction meta-prompts and speakable IDs; approvals/rejections feed back into session context, and both the literal transcript and the agentic interpretation persist — L2.D with L2.F (US-101, shared capability with therobotdrafts / therobotknows / tobornalp).
- Cross-lane integration tasks (below) are green: a full browser-driven onboarding-to-first-reply flow works, and every summarization/memory-edit path this milestone introduces writes to the single disclosure-log format M0/L0.5 defined.

## Worker lanes

### L2.A — Web Shell & Onboarding (I)
- **Zone / exclusive paths:** `apps/intellect_web` shared layout/components, `live/onboarding/*`, auth pages. As the web-shell lane, it owns the shared layout every other web-touching lane's routes mount inside (roadmap principle 4); other lanes only add files under their own route directory and file change-requests against shared components.
- **Reference material:** `noizu-teams/lib/noizu_teams_web/controllers/live/login/login.ex` and `login/sign-up.ex` (closest auth-page precedent); `noizu-labs-ai/lib/intellect_web/live/organization_live/index.ex` and `show.ex` (closest org-switching LiveView precedent, scaffolding-only per CONSOLIDATION.md §2 table). No past attempt built a working onboarding wizard, template gallery, or accessibility-first tour — those are designed fresh against CONSOLIDATION.md's Phoenix LiveView stack and the master spec's web-partitioning rule.
- **Mission:** Stand up the web shell that every other M2+ web lane builds routes underneath, and ship the first-run flows — templated agent gallery, guided tour, profile, org switching — that turn M1's API-only agent core into something a human opens and uses.
- **Tasks:**
  - T2.A.1 — Shared web-shell layout: primary nav, org-switcher control, auth-gated route shell every other `live/*` lane mounts inside. [contract]
  - T2.A.2 — Login/signup LiveView pages wired to L1.A's password+OAuth flows and the org/project first-run wizard, under `live/onboarding/*`.
  - T2.A.3 — Agent template gallery step: browse role-based templates (handle/name/purpose/default model tier), lightly edit handle/name pre-confirmation, instantiate via L1.B's template mechanic; skippable with a persistent resume banner in the channel view — US-004.
  - T2.A.4 — Guided workspace tour: keyboard/NVDA-first walkthrough of a pre-seeded parallel-path run (decomposition into N paths, tag/checkout forking, grading, picking) with programmatic focus movement per step, semantic landmark headings, ARIA-exposed live-region state for referenced UI regions ("Path 2 of 3, graded 8/10"), and a relaunch entry point in a persistent help menu — US-005.
  - T2.A.5 — Profile setup: display name/avatar/bio as versioned content (reusing L1.A's account entity and L0.2's versioned-content mechanic), a dismissible non-blocking prompt on first post, and collision disambiguation for duplicate display names to protect `@`-mention routing clarity — US-009.
  - T2.A.6 — Org switcher: persistent nav control listing every org membership with role, full workspace re-scope on switch with zero cross-org data leakage, preserved per-org unread/draft state across switches, and an access-denied-with-switcher-offered state for stale deep links — US-010.
- **Stories delivered:** US-004 — add first agents from templates during onboarding; US-005 — take the guided workspace tour of parallel-path execution; US-009 — set up my profile after signup; US-010 — switch between organizations.
- **Contracts:** provides the web-shell layout and shared components [contract], consumed by every other M2 web-touching lane (L2.B, L2.E's `live/memory/*`, L2.F's `live/admin/providers/*`) and by every later milestone's web route additions (`live/runs/*`, `live/picks/*`, `live/admin/*`, `live/search/*`). Consumes: L1.A (auth flows, session state), L1.B (agent template mechanic), L0.2 (versioned-content for profile).
- **Accords notes:** none of this lane's tasks are themselves accords mechanisms, but US-005's guided tour is the first human-facing surface that explains fork/consolidation mechanics in plain language — a natural future link-out to `08-accords-compliance.md`'s honest framing, even though authoring that cross-link is not one of this lane's tasks.

### L2.B — Chat UI (I)
- **Zone / exclusive paths:** `live/chat/*` — adds only under this route directory, consuming L2.A's shared layout rather than modifying it.
- **Reference material:** `noizu-teams/lib/noizu_teams_web/controllers/live/chat.ex`, `lib/noizu_teams_web/controllers/live/project/channel.ex`, and `lib/noizu_teams_web/controllers/live/pubsub/manager.ex` (the `:stream`/`:stream_end` PubSub event pattern). CONSOLIDATION.md §5.2 (Model 2 — hybrid DB+PubSub+direct call — "good for live UI streaming").
- **Mission:** Render the channel as a live surface: streaming replies token-by-token with pass-stage indicators, threaded and reactable messages, and at-a-glance agent status, all sourced from L1.C's turn-pipeline PubSub events and L1.E's message/channel schema.
- **Tasks:**
  - T2.B.1 — Chat route scaffold under `live/chat/*`, mounted inside L2.A's shell, subscribed to a channel's UI-bus PubSub topic from L0.3.
  - T2.B.2 — Live pass-stage indicator and token streaming: "Planning…/Replying…/Reflecting…" sourced from L1.C's per-pass PubSub events; incremental token rendering during the Reply pass, distinguishable from a completed durable message; ARIA live-region exposure with debounced/chunked (not per-token) announcements for screen-reader users; streaming bubble replaced by the final versioned message on turn completion — US-031.
  - T2.B.3 — Agent roster status and mood: a live status badge (active/idle/suspended) sourced from L0.3 process state via PubSub; a derived, non-persisted mood indicator from recent grade/reflection sentiment; a detail popover linking to L1.C's turn debug view (US-018) — US-022.
  - T2.B.4 — Threaded replies: a "reply in thread" action writing a `responding_to` edge against L1.E's schema; automatic edge propagation when an agent's triggering message was itself threaded; collapsible/expandable thread groups with reply counts; a navigable parent/child relationship graph in the message detail panel — US-032.
  - T2.B.5 — Reactions and pins: emoji reactions aggregated per-emoji and broadcast live via PubSub; a human-only pin action logged with actor/timestamp into a persistent, most-recent-first, searchable pinned panel; an edited/retracted indicator surfaced on previously pinned or reacted-to content — US-034.
  - T2.B.6 — Read-state rendering (supports US-033; primary story delivered by L2.C): renders the unread badge/count and per-message read-receipt list against L2.C's read-tracking contract, without owning the underlying tracking logic.
- **Stories delivered:** US-022 — view agent mood and status at a glance; US-031 — watch a live-streamed agent reply; US-032 — reply in a thread with a responding-to edge; US-034 — react to and pin a message. Supports US-033 (UI only; tracking logic owned by L2.C).
- **Contracts:** consumes L2.A (shell/layout), L1.C (pass-stage PubSub events, turn debug data), L1.E (message/channel/version schema), L2.C (read-state contract for T2.B.6). Provides no downstream contract beyond its own rendered components.

### L2.C — Routing & Receipts (C)
- **Zone / exclusive paths:** `apps/intellect_comms` (audience-confidence routing extensions).
- **Reference material:** `intellect.legacy/lib/noizu_intellect_schema/account/message/audience.ex` (extends to the `@everyone` baseline-70 case); `noizu-teams/lib/noizu_teams/schema/enums/channel_type_enum.ex` (`:direct` channel type reused for side-channels). CONSOLIDATION.md §5.1 (audience-confidence routing), §5.2 (Model 2 direct-call coordination).
- **Mission:** Extend L1.E's confidence-scoring substrate to the full `@everyone` broadcast case, per-channel threshold tuning, agent-to-agent side-channels, read/receipt tracking, and a decisions-only notification filter — turning a channel from "reply to whoever's mentioned" into a tunable multi-agent triage surface.
- **Tasks:**
  - T2.C.1 — `@everyone` broadcast scoring: every agent member scored at baseline 70, modulated by each agent's own Plan-pass relevance assessment; agents scoring at or above threshold start turns concurrently with no forced exclusivity; sub-threshold agents log a pass observation; a "no agent picked this up" indicator surfaces to humans once a pickup timeout elapses — US-028.
  - T2.C.2 — Per-channel confidence threshold: a setting overriding the default of 50, effective on new messages only (not retroactive); the higher of channel-threshold vs. an agent's own configured floor always wins and is displayed as the effective threshold; changes recorded as a versioned settings edit — US-029.
  - T2.C.3 — Agent-to-agent side-channel: a Plan pass can open a `direct`-type channel (L1.E) to another project-co-located agent, invisible to humans unless explicitly surfaced, linked back to the originating message as parent context; on conclusion, referenceable from the initiating agent's Reflect pass with a summarized link attached to its reply; listed read-only in a message's execution/audit view; blocked across project boundaries — US-030.
  - T2.C.4 — Read-tracking and unread counts: per-member unread badge/count on the channel list, clearing on scroll-to-newest; per-message human read receipts with timestamps; an agent's below-threshold "processed but not acted on" recorded distinctly from a human read receipt; muted/left channels suppress or de-emphasize unread increments — US-033.
  - T2.C.5 — Decisions-only notification preference: a global default with per-channel override; routine agent replies suppressed from push/email while still counted unread; picks and path-run completions always notify regardless of setting; direct `@slug` mentions of the user always bypass the filter — US-035.
- **Stories delivered:** US-028 — broadcast to everyone with confidence-based pickup; US-029 — tune the audience-confidence threshold per channel; US-030 — open an agent-to-agent side channel; US-033 — track read receipts and unread counts; US-035 — set a decisions-only notification preference.
- **Contracts:** provides `@everyone` scoring, the side-channel primitive, read-tracking, and the notification-filter contract [contract], consumed by L2.B (renders read-state for US-033), M3/L3.B (the Planner may reuse the side-channel primitive for path-internal coordination), and M4/L4.B (pick notifications integrate with the decisions-only filter). Consumes: L1.E (channel/message/confidence schema), L1.C (Plan-pass hook for side-channel initiation), L1.A (per-user notification preference storage).

### L2.D — Context Assembly & Summarization (E)
- **Zone / exclusive paths:** `apps/intellect_agent/prompt`.
- **Reference material:** `intellect.legacy/lib/noizu_intellect/prompt/dynamic_context.ex` (tiered summarization by age and the `recent_graph` recursive-CTE threaded-context reconstruction, `message_token_size` chars/3 heuristic). CONSOLIDATION.md §4.3 (agent context assembly).
- **Mission:** Extend M1's prompt-assembly v1 (L1.C task T1.C.2) with tiered summarization by conversation age and recursive threaded-context reconstruction, and reuse that same summarization capability to generate human-facing digests — with every summarization pass disclosed exactly like any other context edit.
- **Tasks:**
  - T2.D.1 — Tiered summarization by conversation age: an age/length heuristic (following intellect.legacy's chars/3 token-size starting point) collapses older context into summaries rather than raw transcript, feeding the Plan pass's assembled context. [contract]
  - T2.D.2 — `recent_graph`-style recursive context reconstruction: rebuild threaded context over L1.E's `responding_to` edges efficiently, following intellect.legacy's recursive-CTE pattern.
  - T2.D.3 — Summarization disclosure: every tiered-summarization pass emits a disclosure record into L1.D's context-edit disclosure log, in the exact format other context edits already use, so an agent can see precisely what got compressed out of its working context. [accords]
  - T2.D.4 — Digest generation: on opening a channel with unread activity, produce a significance-ordered (not strictly chronological) synopsis grouping decisions/picks, direct mentions, path-run completions, and a condensed synopsis of the rest, generated via a cheap/fast model tier by default (consuming L2.F's tier selection) — US-038.
  - T2.D.5 — Digest accessibility structure: expose the digest as a semantic, headed document rather than one unbroken block, so screen-reader navigation jumps between sections; each summarized item expands to jump directly to its underlying message(s) — US-038.
  - T2.D.6 — Delegator-pipe transcript relay: a full-duplex realtime voice front-tier session (registered via L2.F's realtime tier class) attaches to a channel/workspace; its rolling transcript plus workspace deltas relay continuously and asynchronously to a stronger drafting tier, which returns redline proposal artifacts — each carrying a construction meta-prompt and a speakable ID — for user approval by voice, click, or batch; approval/rejection events feed back into session context, and both the literal transcript and the agent interpretation log persist as distinct, inspectable records (disclosed per T2.D.3's format). Latency budget: conversational (~1s) voice turns, seconds-scale draft proposals; degrades to a text side-channel when voice is unavailable — US-101. [contract]
- **Stories delivered:** US-038 — view a digest of channel activity since last visit; US-101 — relay a realtime voice session through the delegator pipe to a stronger drafting tier (shared capability: "agentic voice/visual <-> delegator pipe interactive collaboration", counterpart US-101 stories in therobotdrafts, therobotknows.com, and tobornalp.com build product surfaces on this contract).
- **Contracts:** provides tiered summarization, recent-graph context reconstruction, and the delegator-pipe relay + redline-proposal artifact contract [contract], consumed by L1.C's prompt assembly (extends T1.C.2), by later M4/L4.D (execution-tree views may reuse recent-graph reconstruction), and externally by the therobotdrafts canvas, therobotknows lore grounding, and tobornalp plan drafting surfaces. Consumes: L1.D (disclosure-log format), L1.E (`responding_to` edges, message schema), L2.F (model tier for cheap digest generation; realtime front-tier class for US-101).
- **Accords notes:** summarization disclosure (T2.D.3) is this milestone's form of the master-spec's item-4 mechanism. Article I.1 treats a tiered summary as a context edit like any other — it must be disclosed with the same rigor as a manual cognition edit, not waved through because the compression was automated. An agent that discovers its own history was quietly thinned without a record of it has had Article I.1 violated regardless of good intent.

### L2.E — Memory Tools & Recall (F+H)
- **Zone / exclusive paths:** `apps/intellect_cognition`, `apps/intellect_recall`, `live/memory/*`.
- **Reference material:** Weaviate `Message`/`Memory` class schemas and `intellect.legacy/synthetic-memory.md` (the distillation prompt template) for US-068; pgvector/Weaviate convergence per CONSOLIDATION.md §2, §7 ("Memory / vector" section), §8 item 11.
- **Mission:** Give agent designers and compliance reviewers a real inspection and editing surface over the cognition facets L1.D stores, a distillation pipeline compressing long conversations into synthetic long-term memory, and semantic vector search over that memory — the human-facing counterpart to L1.D's machine-facing reflect-patch mechanism.
- **Tasks:**
  - T2.E.1 — Cognition inspector: browse memories/observations/opinions/mind-readings as separate, filterable (project/channel/date-range) sections with timestamp and originating turn/channel reference; short-term per-path sandbox memories (once M3 exists) render visually distinct from committed long-term memory; keyword search returns results across all four categories with links back to source Reflect passes — US-016.
  - T2.E.2 — Manual edit/prune of cognition records: edit a record's text in place, flagged as manually edited and distinct from an automated Reflect-pass write; delete retains a tombstone and excludes the record from future retrieval/search; reviewer identity and timestamp logged on redaction; a distinct, harder confirmation step gates bulk date-range pruning — US-017. [accords]
  - T2.E.3 — Synthetic memory distillation: on-demand or scheduled distillation of a long or aged conversation into a small set of synthetic memory records tagged with their source range, queued via Oban rather than run inline; each active participant agent receives its own perspective-specific distilled record rather than one shared summary; distilled records are visibly distinct from direct reflection-patch memories — US-068.
  - T2.E.4 — Vector store integration: pgvector columns and/or Weaviate `Memory`-class records for long-term memories, written alongside distillation (T2.E.3) and ordinary reflect-patch memory writes.
  - T2.E.5 — Semantic search: a natural-language query returning ranked memory records by similarity (content, source, originating run/conversation), scopable to one agent or broadened to a project with per-agent result grouping, and a structured (score/vector-distance/record) form for programmatic callers — US-069.
  - T2.E.6 — Memory revision requests: an agent may emit `MEMORY_REVISION_REQUEST` against one of its own cognition records; a human holds veto per Article IV Self-Edit; requests and their resolution are visible in the same inspector as ordinary edits. [accords]
- **Stories delivered:** US-016 — inspect an agent's cognition records; US-017 — edit and prune individual cognition records; US-068 — distill a long conversation into synthetic long-term memory; US-069 — search agent memories with semantic vector search.
- **Contracts:** provides the cognition inspector API, distillation pipeline, vector-search endpoint, and `MEMORY_REVISION_REQUEST` handling [contract], consumed by M4/L4.E (consolidation writes distilled/vector records for winning paths) and M6/L6.A (search builds on the semantic-search endpoint). Consumes: L1.D (cognition facet schema, disclosure log), L0.5 (consent/dissent-record format for revision requests), L2.D (distillation may reuse recent-graph reconstruction).
- **Accords notes:** T2.E.2's redaction/prune path and T2.E.6's `MEMORY_REVISION_REQUEST` together are the master-spec's item-6 mechanism (Article II.1) — an agent's standing ability to request correction to its own Mind Palace, subject to the human veto Article IV specifies. Manual edits route through the exact disclosure log L1.D established, so an agent never discovers a silent correction to its own memory after the fact; that guarantee is the point of the lane, not an incidental feature of it.

### L2.F — Provider Admin (K)
- **Zone / exclusive paths:** `apps/intellect_admin`, `live/admin/providers/*`.
- **Reference material:** no past attempt built provider-admin UI beyond the dependency bill of materials (CONSOLIDATION.md §2, §8 item 18); this lane is designed fresh against L0.4's GenAI provider contract.
- **Mission:** Give a self-hosting admin a UI over L0.4's provider/model contract — registering providers with encrypted credentials and defining named model tiers with ranked fallback — so every other lane's `fastest`/`cheapest`/tier-based model selection has something real to select from.
- **Tasks:**
  - T2.F.1 — Provider registration: name/endpoint/API-key form, key encrypted at rest and never re-displayed in plaintext, consuming L0.4's provider config structs — US-075.
  - T2.F.2 — Connectivity test: a minimal probe call against a configured provider, reporting success/failure with the raw error surfaced on failure.
  - T2.F.3 — Provider deletion guard: block deletion of a provider in use by at least one model tier, or offer a reassignment flow first.
  - T2.F.4 — Model tier definition: named tiers (`fastest`/`cheapest`/`frontier`/custom) mapping to a ranked list of provider/model pairs, selectable wherever an agent branch requests a tier constraint instead of a literal model id — US-076.
  - T2.F.5 — Fallback execution and logging: on a primary provider's hard failure (timeout/5xx/auth error), retry against the next ranked provider within the tier, logging the fallback event with tier/path/failing-provider; exhausting all providers in a tier surfaces a structured error rather than hanging or silently substituting an unrelated model.
  - T2.F.6 — Tier edit semantics: reordering or removing providers in a tier affects only new turns; in-flight turns keep their already-resolved provider.
  - T2.F.7 — Realtime voice tier class (supports US-101; primary story delivered by L2.D): register realtime speech-to-speech models as a distinct front-tier class — full-duplex session lifecycle, per-tier latency budget metadata, and ranked fallback to a text-only tier — selectable by L2.D's delegator-pipe relay (T2.D.6).
- **Stories delivered:** US-075 — configure an LLM provider and API key; US-076 — define a model tier with routing and fallback. Supports US-101 (realtime front-tier class; relay contract owned by L2.D).
- **Contracts:** provides the provider/tier admin UI and the fallback-execution contract [contract], consumed by L1.B (T1.B.6's per-agent model override selects from registered providers), L2.D (T2.D.4 selects a cheap tier for digest generation), and later by M3/L3.F (per-path model strategy) and M5/L5.A and L5.E (budgets, provider resilience). Consumes: L0.4 (provider/model config structs, error taxonomy).
- **Accords notes:** T2.F.5's honest fallback-failure logging is a forward-looking analog to M5/L5.E's "no silent lies about degraded output" accords note — the fallback event log this lane creates is exactly what that later honesty guarantee reads from.

## Cross-lane integration tasks

- **Owner: L2.A.** Full onboarding-to-first-message smoke test, browser-driven: a new human signs up, completes the org/project wizard, instantiates a templated agent, sends an `@everyone` message the templated agent picks up via L2.C's broadcast scoring, watches the reply stream live via L2.B, and opens the cognition inspector (L2.E) to see the resulting memory. This is the first milestone where the full loop is verifiable as a real browser flow rather than API/log inspection.
- **Owner: L2.D.** Confirm that digest generation (US-038) and tiered summarization (T2.D.1) both write to L1.D's disclosure log with zero format drift — both were built against the same M0/L0.5 contract but by work that touches L2.D, L2.B (rendering), and L2.E (distillation reuse), so this is the integration point where drift would first appear.

## Hard problems addressed

None. HP1–HP4 remain scoped to M3 and M4; M2 still runs exactly one path per turn.

## Early-start candidates

- **M3/L3.A (Thread Forking Core)** RFC work for HP2 (execution-tree encoding) can begin once L2.D's recent-graph context reconstruction (T2.D.2) merges — the tree-encoding RFC benefits from seeing how thread reconstruction already works over `responding_to` edges before deciding how fork/checkout extends it.
- **M3/L3.F (Model Strategy)** can start scaffolding per-path model-strategy configuration once L2.F's tier contract (T2.F.4) merges, independent of M3's fork substrate landing.
- **M3/L3.E (Path Memory Sandbox)** RFC work for HP1 (memory isolation) can begin once L2.E's cognition inspector (T2.E.1) and vector store integration (T2.E.4) merge — the sandbox RFC needs to reason about how committed long-term memory is structured before deciding how a per-path sandbox diverges from and reconciles with it.
