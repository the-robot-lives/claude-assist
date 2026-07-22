# Story Coverage & Traceability Matrix

Every one of the 100 user stories (`../user-stories/US-0XX-*.md`) is assigned to exactly one primary
milestone and lane, per the roadmap's master allocation (see [`00-overview.md`](00-overview.md)).
Rows are grouped by milestone, then by lane in the order the lane appears in that milestone's doc.
A story appears in the **Notes** column when a second lane materially supports its delivery; that is
the only kind of duplication this matrix records — every story still has exactly one primary owner.

Count check: M0=0, M1=20, M2=20, M3=13, M4=18, M5=14, M6=15 → 100.

## M0 — Bedrock

No stories are assigned to M0 — it is pure enablement (repo/CI skeleton, core schema, runtime
topology, GenAI provider layer, agent charter). All 100 stories are delivered in M1–M6 below. See
[`01-M0-bedrock.md`](01-M0-bedrock.md) for its five lanes.

## M1 — Single-Path Agent Core

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-001 | Create an account with password or OAuth | must-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-002 | Create my first org and project | must-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-003 | Invite human team members with roles | must-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-006 | Manage active sessions across devices | should-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-007 | Recover account credentials | should-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-008 | Accept terms of service and org policies | must-have | Onboarding & Identity | L1.A Identity & Access | `apps/intellect_identity` | |
| US-011 | Create a new agent with identity prompts | must-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-012 | Edit agent definition with versioned diff history | must-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-013 | Roll back an agent prompt to a prior version | must-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-014 | Assign an agent to a project and team | must-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-020 | Save and instantiate an agent template | should-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-023 | Set a per-agent model override | should-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-024 | Delete or archive an agent safely | must-have | Agents & Cognition | L1.B Agent Lifecycle | `apps/intellect_core` | |
| US-015 | Wake and suspend an agent process | must-have | Agents & Cognition | L1.C Turn Pipeline | `apps/intellect_agent` | |
| US-018 | View a turn's Plan/Reply/Reflect passes for debugging | must-have | Agents & Cognition | L1.C Turn Pipeline | `apps/intellect_agent` | |
| US-019 | Create and track agent objectives and reminders | must-have | Agents & Cognition | L1.D Cognition Store | `apps/intellect_cognition` | Heartbeat mechanic [accords] |
| US-025 | Create a channel of a specific type | must-have | Channels & Messaging | L1.E Channels Core | `apps/intellect_comms` | |
| US-026 | Add human and agent members to a channel | must-have | Channels & Messaging | L1.E Channels Core | `apps/intellect_comms` | |
| US-027 | Mention a specific agent to route a message | must-have | Channels & Messaging | L1.E Channels Core | `apps/intellect_comms` | |
| US-037 | Retract or edit a message with a version trail | must-have | Channels & Messaging | L1.E Channels Core | `apps/intellect_comms` | |

## M2 — Conversational Workspace

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-004 | Add first agents from templates during onboarding | must-have | Onboarding & Identity | L2.A Web Shell & Onboarding | `apps/intellect_web` (`live/onboarding/*`) | |
| US-005 | Take the guided workspace tour of parallel-path execution | should-have | Onboarding & Identity | L2.A Web Shell & Onboarding | `apps/intellect_web` (`live/onboarding/*`) | |
| US-009 | Set up my profile after signup | could-have | Onboarding & Identity | L2.A Web Shell & Onboarding | `apps/intellect_web` (`live/onboarding/*`) | |
| US-010 | Switch between organizations | could-have | Onboarding & Identity | L2.A Web Shell & Onboarding | `apps/intellect_web` (`live/onboarding/*`) | |
| US-022 | View agent mood and status at a glance | could-have | Agents & Cognition | L2.B Chat UI | `apps/intellect_web` (`live/chat/*`) | |
| US-031 | Watch a live-streamed agent reply | should-have | Channels & Messaging | L2.B Chat UI | `apps/intellect_web` (`live/chat/*`) | |
| US-032 | Reply in a thread with a responding-to edge | could-have | Channels & Messaging | L2.B Chat UI | `apps/intellect_web` (`live/chat/*`) | |
| US-034 | React to and pin a message | could-have | Channels & Messaging | L2.B Chat UI | `apps/intellect_web` (`live/chat/*`) | |
| US-028 | Broadcast to everyone with confidence-based pickup | must-have | Channels & Messaging | L2.C Routing & Receipts | `apps/intellect_comms` | |
| US-029 | Tune the audience-confidence threshold per channel | should-have | Channels & Messaging | L2.C Routing & Receipts | `apps/intellect_comms` | |
| US-030 | Open an agent-to-agent side channel | could-have | Channels & Messaging | L2.C Routing & Receipts | `apps/intellect_comms` | |
| US-033 | Track read receipts and unread counts | should-have | Channels & Messaging | L2.C Routing & Receipts | `apps/intellect_comms` | UI rendering of receipts/unread counts is supported by L2.B Chat UI |
| US-035 | Set a decisions-only notification preference | must-have | Channels & Messaging | L2.C Routing & Receipts | `apps/intellect_comms` | |
| US-038 | View a digest of channel activity since last visit | should-have | Channels & Messaging | L2.D Context Assembly & Summarization | `apps/intellect_agent/prompt` | Summarization emits disclosure records [accords] |
| US-016 | Inspect an agent's memories, observations, opinions, and mind-readings | must-have | Agents & Cognition | L2.E Memory Tools & Recall | `apps/intellect_cognition` + `apps/intellect_recall` + `live/memory/*` | |
| US-017 | Edit and prune individual cognition records | must-have | Agents & Cognition | L2.E Memory Tools & Recall | `apps/intellect_cognition` + `apps/intellect_recall` + `live/memory/*` | Edit/prune disclosure + `MEMORY_REVISION_REQUEST` [accords] |
| US-068 | Distill a long conversation into synthetic long-term memory | should-have | Memory & Knowledge | L2.E Memory Tools & Recall | `apps/intellect_cognition` + `apps/intellect_recall` + `live/memory/*` | |
| US-069 | Search agent memories with semantic vector search | must-have | Memory & Knowledge | L2.E Memory Tools & Recall | `apps/intellect_cognition` + `apps/intellect_recall` + `live/memory/*` | |
| US-075 | Configure an LLM provider and API key | must-have | Admin & Platform Ops | L2.F Provider Admin | `apps/intellect_admin` + `live/admin/providers/*` | |
| US-076 | Define a model tier with routing and fallback | must-have | Admin & Platform Ops | L2.F Provider Admin | `apps/intellect_admin` + `live/admin/providers/*` | |
| US-101 | Relay a realtime voice session through the delegator pipe to a stronger drafting tier | must-have | Agentic Voice & Visual Collaboration | L2.D Context Assembly & Summarization | `apps/intellect_agent/prompt` | Realtime front-tier class supported by L2.F (T2.F.7); shared capability with therobotdrafts / therobotknows.com / tobornalp.com (each has a counterpart US-101) |

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-042 | Tag a conversation checkpoint | should-have | Parallel-Path Execution | L3.A Thread Forking Core | `apps/intellect_paths/thread` | [rfc HP2] execution-tree encoding |
| US-043 | Fork a thread from a tag manually | should-have | Parallel-Path Execution | L3.A Thread Forking Core | `apps/intellect_paths/thread` | [rfc HP2] |
| US-039 | Submit a request for parallel-path decomposition | must-have | Parallel-Path Execution | L3.B Planner | `apps/intellect_paths/planner` | |
| US-040 | Review and edit the Planner's path breakdown before launch | should-have | Parallel-Path Execution | L3.B Planner | `apps/intellect_paths/planner` | |
| US-041 | Set path count and per-run caps | must-have | Parallel-Path Execution | L3.B Planner | `apps/intellect_paths/planner` | |
| US-044 | Launch N paths that fork from a shared base context | must-have | Parallel-Path Execution | L3.C Path Executor | `apps/intellect_paths/executor` | Contract for M4 pick/review UI |
| US-047 | Pause and resume a single path | should-have | Parallel-Path Execution | L3.C Path Executor | `apps/intellect_paths/executor` | |
| US-048 | Cancel a runaway path mid-flight | must-have | Parallel-Path Execution | L3.C Path Executor | `apps/intellect_paths/executor` | |
| US-049 | Let a path's agents exchange turns within the path | must-have | Parallel-Path Execution | L3.C Path Executor | `apps/intellect_paths/executor` | |
| US-056 | Resume an interrupted run after disconnect or restart | must-have | Parallel-Path Execution | L3.D Run Durability | `apps/intellect_runtime` + Oban | |
| US-096 | Recover a run after server restart with no lost or duplicated turns | must-have | Edge Cases, Errors, Performance & Accessibility | L3.D Run Durability | `apps/intellect_runtime` + Oban | |
| US-055 | Isolate each path's short-term memory sandbox | must-have | Parallel-Path Execution | L3.E Path Memory Sandbox | `apps/intellect_cognition` | [rfc HP1]; fork-disclosure preamble + dissent log [accords] |
| US-045 | Select a per-path model strategy | could-have | Parallel-Path Execution | L3.F Model Strategy | `apps/intellect_genai` + `apps/intellect_admin` | |

## M4 — Review, Reward & Consolidation [HP3, HP4]

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-051 | Emit a normalized outcome record on path completion | must-have | Parallel-Path Execution | L4.A Grading & Outcomes | `apps/intellect_paths/review` | [rfc HP3] |
| US-057 | Grade completed path outcomes against criteria | must-have | Review & Reward | L4.A Grading & Outcomes | `apps/intellect_paths/review` | |
| US-058 | See a ranked top-K shortlist of path outcomes | must-have | Review & Reward | L4.A Grading & Outcomes | `apps/intellect_paths/review` | |
| US-059 | Compare outcomes side-by-side in plain language | must-have | Review & Reward | L4.B Pick Flow | `apps/intellect_paths/pick` + `live/picks/*` | |
| US-060 | Pick a winner with a one-line rationale | must-have | Review & Reward | L4.B Pick Flow | `apps/intellect_paths/pick` + `live/picks/*` | |
| US-061 | Reject all outcomes and request a re-plan | should-have | Review & Reward | L4.B Pick Flow | `apps/intellect_paths/pick` + `live/picks/*` | |
| US-066 | Delegate the pick to a Picker agent with human veto | could-have | Review & Reward | L4.B Pick Flow | `apps/intellect_paths/pick` + `live/picks/*` | |
| US-062 | Back-propagate reward weight onto the winning path's decision factors | must-have | Review & Reward | L4.C Decision Weights | `apps/intellect_paths/weights` | [rfc HP4] |
| US-063 | View decision-weight history and its effect on planning | should-have | Review & Reward | L4.C Decision Weights | `apps/intellect_paths/weights` | |
| US-064 | Freeze reward updates for controlled experiments | could-have | Review & Reward | L4.C Decision Weights | `apps/intellect_paths/weights` | |
| US-021 | A/B compare two prompt versions via forked runs | should-have | Agents & Cognition | L4.D Run Visualization & Comparison | `live/runs/*` | |
| US-046 | Watch live progress across concurrent paths | must-have | Parallel-Path Execution | L4.D Run Visualization & Comparison | `live/runs/*` | |
| US-052 | View the full execution tree of a run | should-have | Parallel-Path Execution | L4.D Run Visualization & Comparison | `live/runs/*` | Phantom-limb archive supports replay [accords] |
| US-053 | Re-run a single losing path with modifications | could-have | Parallel-Path Execution | L4.D Run Visualization & Comparison | `live/runs/*` | Phantom-limb archive [accords] |
| US-054 | Compare sibling paths turn-by-turn | could-have | Parallel-Path Execution | L4.D Run Visualization & Comparison | `live/runs/*` | |
| US-067 | Write back only the winning path's memories | must-have | Memory & Knowledge | L4.E Consolidation & Consent | `apps/intellect_cognition` + `apps/intellect_recall` | Winner-only write-back + consolidation-consent step [accords] |
| US-070 | Inspect which memories informed a given reply | should-have | Memory & Knowledge | L4.E Consolidation & Consent | `apps/intellect_cognition` + `apps/intellect_recall` | Memory-provenance |
| US-050 | Send a deferred message that awaits another thread's tagged completion | could-have | Parallel-Path Execution | L4.F Deferred Messaging | `apps/intellect_comms` | |

## M5 — Governance, Ops & Trust

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-077 | Set org/project token budgets and per-request path caps | must-have | Admin & Platform Ops | L5.A Budgets & Spend | `apps/intellect_admin` | |
| US-078 | View token spend by agent, run, and user | should-have | Admin & Platform Ops | L5.A Budgets & Spend | `apps/intellect_admin` | |
| US-079 | Monitor queue depth and agent process health | must-have | Admin & Platform Ops | L5.B Health & Backpressure | `apps/intellect_runtime` + `live/admin/health/*` | |
| US-100 | Stay responsive at scale with backpressure indicators instead of silent stalls | should-have | Edge Cases, Errors, Performance & Accessibility | L5.B Health & Backpressure | `apps/intellect_runtime` + `live/admin/health/*` | |
| US-080 | Manage member roles and permissions | must-have | Admin & Platform Ops | L5.C Access Governance | `apps/intellect_identity` + `apps/intellect_admin` | |
| US-082 | Test an upgrade in a staging org before rollout | could-have | Admin & Platform Ops | L5.C Access Governance | `apps/intellect_identity` + `apps/intellect_admin` | Partial analog to Accords Article II.2 consensus-upgrade voting [accords] |
| US-083 | Review an audit log of admin actions | should-have | Admin & Platform Ops | L5.C Access Governance | `apps/intellect_identity` + `apps/intellect_admin` | |
| US-071 | Redact memories referencing a subject with audit log | must-have | Memory & Knowledge | L5.D Data Governance & Ledger | `apps/intellect_cognition` + `apps/intellect_recall` | Redaction w/ tombstones + audit trail [accords] |
| US-072 | Set memory retention policies per project | should-have | Memory & Knowledge | L5.D Data Governance & Ledger | `apps/intellect_cognition` + `apps/intellect_recall` | |
| US-073 | Enforce cross-project memory isolation | must-have | Memory & Knowledge | L5.D Data Governance & Ledger | `apps/intellect_cognition` + `apps/intellect_recall` | |
| US-081 | Configure data retention and storage bounds | should-have | Admin & Platform Ops | L5.D Data Governance & Ledger | `apps/intellect_cognition` + `apps/intellect_recall` | Optional SHA-256 hash-chain task [accords] |
| US-095 | Recover gracefully from LLM provider errors mid-turn | must-have | Edge Cases, Errors, Performance & Accessibility | L5.E Provider Resilience | `apps/intellect_genai` | No silent lies about degraded output [accords] |
| US-065 | View decision history with outcome tracking | should-have | Review & Reward | L5.F Provenance & History | `apps/intellect_core` + `live/decisions/*` | |
| US-089 | Jump from a message to its prompt version, author agent, and turn record | must-have | Search & Discovery | L5.F Provenance & History | `apps/intellect_core` + `live/decisions/*` | |

## M6 — Reach: Search, API & Accessibility

| US-ID | Title | Priority | Epic | Lane | Zone/App | Notes |
|---|---|---|---|---|---|---|
| US-036 | Search channel history | should-have | Channels & Messaging | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-084 | Search across channels, messages, agents, and runs | must-have | Search & Discovery | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-085 | Run a semantic search over message history | should-have | Search & Discovery | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-086 | Filter runs by status, project, date, and outcome | must-have | Search & Discovery | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-087 | Find which agent knows about a topic | should-have | Search & Discovery | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-088 | Browse the agent and template directory | should-have | Search & Discovery | L6.A Search | `apps/intellect_recall/search` + `live/search/*` | |
| US-090 | Submit and poll a run via the API | must-have | Integration & API | L6.B Public API & Integrations | `apps/intellect_api` | |
| US-091 | Subscribe to webhooks for run lifecycle events | should-have | Integration & API | L6.B Public API & Integrations | `apps/intellect_api` | |
| US-092 | Run a scripted experiment with pinned models and prompts | must-have | Integration & API | L6.B Public API & Integrations | `apps/intellect_api` | |
| US-093 | Bulk export run data with anonymization options | should-have | Integration & API | L6.B Public API & Integrations | `apps/intellect_api` | |
| US-094 | Bridge an external chat platform to a channel | could-have | Integration & API | L6.B Public API & Integrations | `apps/intellect_api` | |
| US-098 | Use screen-reader digest mode with configurable per-agent verbosity | must-have | Edge Cases, Errors, Performance & Accessibility | L6.C Accessibility | `live/*` (markup only) | |
| US-099 | Navigate the execution tree and outcome-picking flow by keyboard as semantic lists | must-have | Edge Cases, Errors, Performance & Accessibility | L6.C Accessibility | `live/*` (markup only) | |
| US-097 | Use low-bandwidth mode with reduced streaming payloads and reconnect reconciliation | should-have | Edge Cases, Errors, Performance & Accessibility | L6.D Low-bandwidth & Transport | transport layer (owns transport, not markup) | |
| US-074 | Export a run's full record as structured data | should-have | Memory & Knowledge | L6.E Research Export | `apps/intellect_recall` | |

## Epic → milestone summary

| Epic | Milestone(s) |
|---|---|
| Onboarding & Identity | M1, M2 |
| Agents & Cognition | M1, M2, M4 |
| Channels & Messaging | M1, M2, M6 |
| Parallel-Path Execution | M3, M4 |
| Review & Reward | M4, M5 |
| Memory & Knowledge | M2, M4, M5, M6 |
| Admin & Platform Ops | M2, M5 |
| Search & Discovery | M5, M6 |
| Integration & API | M6 |
| Edge Cases, Errors, Performance & Accessibility | M3, M5, M6 |
