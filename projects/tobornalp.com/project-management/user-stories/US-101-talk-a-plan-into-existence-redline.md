---
id: US-101
title: "Talk a plan into existence with a voice agent that drafts tasks in redline"
personas: [lin-zhao, sarah-kim]
domain: projects
priority: high
mvp_phase: "v0.4"
shared_capability: "agentic voice/visual <-> delegator pipe interactive collaboration"
shared_with: [therobotdrafts, noizu-intellect, therobotknows.com]
---

## User Story

As a **Sarah Kim (Engineering Lead / acting PM)**, I want to talk through a plan — a feature rollout, a sprint, a quarter — while optionally sketching rough groupings and arrows on a planning canvas, and have a voice agent ask me clarifying questions while a stronger drafting layer drafts structured epics, tasks, dependencies, and milestones ahead of me in redline mode, so that a spoken braindump becomes a reviewed, structured plan in one session instead of notes I have to re-enter as tickets by hand.

## Acceptance Criteria

- [ ] Starting a planning voice session opens a full-duplex conversation with a low-latency realtime voice agent; talking never blocks the canvas and sketching never interrupts the agent — the two run concurrently
- [ ] The voice agent converses back-and-forth as a pair planner: it acknowledges narration, asks clarifying questions about ambiguous scope or sequencing ("does the API freeze block the mobile track or just web?"), and proposes structure — it is not a dictation service
- [ ] The rolling transcript plus canvas deltas (rough groupings, arrows) stream through the delegator pipe to a stronger drafting-layer model that works asynchronously ahead of the user
- [ ] The drafting layer proposes concrete plan elements — epics, tasks, dependency edges, and milestones — in **redline mode** below or over the conversation: visually distinct, non-destructive, and clearly attributed to the agent
- [ ] Every proposed element carries a **construction meta-prompt** — estimate rationale, suggested assignee (including agent teammates), and the dependency edges it implies — which the user and agents can open, review, and tweak; edits re-render the element
- [ ] Every redline element displays a short **speakable ID** (e.g. `R-3`); approval works by voice ("approve R-3 through R-6", "reject R-7"), right-click approve/reject, direct manipulation, or batch approve-all — approved elements graduate from redline into first-class plan items
- [ ] Rejections and tweaks feed back to the drafting layer within the session so subsequent proposals reflect the correction (revised estimates, reassigned owners, re-routed dependencies)
- [ ] The resulting plan persists **both** the full literal transcript and the agent's structured interpretation log, replayable and auditable after the fact so the team can answer "why did we scope it this way?"
- [ ] Latency budgets: voice turn-taking feels conversational (~1s perceived); redline drafts surface within a few seconds of the motivating utterance or stroke; larger drafts arrive incrementally rather than blocking
- [ ] Degrades gracefully: works with or without the canvas, and with voice unavailable a text side-channel drives the same clarify/propose/approve loop

## Notes

This is tobornalp's manifestation of the shared **agentic voice/visual ↔ delegator-pipe interactive collaboration** capability: a cheap, low-latency realtime voice model converses with the user while transcript and workspace deltas stream through a delegator pipe to a stronger drafting model that proposes concrete artifacts in redline mode, each carrying a construction meta-prompt and a speakable ID, approved by voice/click/batch, with both the literal transcript and the agentic interpretation stored on the result.

Here the surface is the plan rather than a design canvas — structured epics/tasks/dependencies/milestones instead of shapes and schemas. Sibling `US-101` stories express the same pattern over other surfaces:

- **therobotdrafts** US-101: voice pair-designer drafting ahead over a sketch/model canvas (the canonical sibling)
- **noizu-intellect**: provides the underlying **delegator pipe** — agent tiering, transcript relay, and memory of decisions made in-session
- **therobotknows.com**: knowledge grounding so the drafting layer's proposals reflect project/domain context

The `shared_capability` / `shared_with` frontmatter keys are the cross-project linking convention; counterpart stories carry the same `shared_capability` string. Dual storage of literal transcript vs. agentic interpretation is a hard requirement — audit trust in the plan depends on always being able to see what was actually said. Serves both Sarah Kim's acting-PM planning JTBD and Lin Zhao's need to spin up structured platform work quickly; complements the agent-as-team-member triage flow (US-008).
