---
id: US-101
title: "Relay a realtime voice session through the delegator pipe to a stronger drafting tier"
slug: relay-a-realtime-voice-session-through-the-delegator-pipe-to-a-stronger-drafting-tier
personas: [P-006, P-002]
epic: "Agentic Voice & Visual Collaboration"
priority: must-have
complexity: high
tags: [voice, realtime, delegator-pipe, provider-tiers, redline, transcript, degradation]
shared_capability: "agentic voice/visual <-> delegator pipe interactive collaboration"
shared_with: [therobotdrafts, therobotknows.com, tobornalp.com]
---

# US-101: Relay a Realtime Voice Session Through the Delegator Pipe to a Stronger Drafting Tier

## User Story

**As a** self-hosting platform admin (Nadia Volkov) who owns provider tiers, and an agent designer (Mara Lindqvist) who wires conversational agents onto them
**I want to** register a cheap low-latency realtime voice model as a front tier and have intellect continuously relay its transcript and workspace context — asynchronously, without blocking the conversation — to a stronger drafting tier that returns reviewable redline proposals
**So that** any product built on intellect gets the voice-pair-designer interaction for free from the infrastructure, with both what the user literally said and how the agent interpreted it durably stored, and it degrades to text when voice is unavailable

## Acceptance Criteria

- **Given** a realtime voice model is configured as a front-tier provider alongside one or more stronger drafting tiers
  **When** an agent designer attaches a full-duplex voice session to a workspace/thread
  **Then** the session opens with concurrent speech-in and agent-speech-out — conversational turn-taking (clarifying questions, back-and-forth) runs against the front tier without blocking on the drafting tier

- **Given** an attached voice session producing a rolling transcript plus workspace deltas
  **When** the user speaks and edits the workspace
  **Then** transcript and context are relayed through the delegator pipe to the drafting tier asynchronously and non-blocking, so front-tier responsiveness is never gated on drafting-tier latency

- **Given** the drafting tier has produced a proposal from the relayed context
  **When** it returns to the session
  **Then** the proposal arrives as a reviewable redline object carrying a construction meta-prompt and a short speakable ID (e.g. `R-4`), distinct from committed workspace state and clearly attributed to the agent

- **Given** a redline proposal is presented in the session
  **When** the user approves or rejects it by voice ("approve R-4"), by speakable ID, or by right-click/direct manipulation
  **Then** the approval/rejection event is fed back into both the live session context — so subsequent proposals reflect the correction — and into memory as a durable decision record

- **Given** an active voice session
  **When** the conversation and drafting proceed
  **Then** the session artifact persists **both** the literal transcript and a separate agent-interpretation log, each independently inspectable and replayable after the fact

- **Given** latency budgets for the pipe
  **When** the user converses and the drafting tier works ahead
  **Then** voice turn-taking feels conversational (~1s perceived) while draft proposals surface on a seconds-scale, slower drafts arriving incrementally rather than blocking the front-tier conversation

- **Given** the front-tier voice provider is unavailable, unregistered, or disabled by the admin
  **When** a session is attached
  **Then** the same clarify → relay → propose → approve loop runs over a text side-channel against the drafting tier, degrading gracefully to text-only with no loss of the dual-storage or approval-feedback behavior

- **Given** an admin (Nadia Volkov) managing provider tiers
  **When** registering, swapping, or budgeting the front and drafting tiers
  **Then** tier assignment, per-tier model, and cost/latency posture are configurable without code changes, and the pipe binds whichever providers are assigned to the front and drafting roles

## Notes
This is intellect's manifestation of the shared **agentic voice/visual ↔ delegator-pipe interactive collaboration** capability: intellect provides the pipe itself — front-tier registration, asynchronous transcript/context relay, redline proposal objects with construction meta-prompts, approval feedback into context and memory, and dual literal/interpretation storage — that downstream products build on. Sibling stories all carry the number **US-101** and the same `shared_capability` string: [[therobotdrafts]] (voice pair-designer over the sketch/model canvas), [[therobotknows.com]] (lore/knowledge grounding for the drafting layer), and [[tobornalp.com]] (plan drafting over the same interaction pattern).

The `shared_capability`/`shared_with` frontmatter keys establish the cross-project linking convention; counterpart stories reference back with the same `shared_capability` string. Roadmap home is **M2 Conversational Workspace** — lane **L2.D** (context/summarization, which drives the relay and rolling-transcript behavior) and lane **L2.F** (provider tiers, which own front-tier voice registration and the front/drafting tier split). Dual storage of literal transcript vs. agentic interpretation is a hard requirement — trust in the pipe depends on always being able to see what was actually said. Complements the provider/tier concerns in [[US-100]] backpressure work where the drafting tier is one more throttled consumer.
