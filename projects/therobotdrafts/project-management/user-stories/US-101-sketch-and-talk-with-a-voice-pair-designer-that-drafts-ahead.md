---
id: US-101
persona: P-001
persona_slug: trd-systems-architect
title: "Sketch and talk with a voice pair-designer that drafts ahead of me"
epic: "Agentic pair-design & voice collaboration"
priority: P0
segment: primary
tags: [voice, sketch, agentic, pair-design, redline, realtime, delegator-pipe]
shared_capability: "agentic voice/visual <-> delegator pipe interactive collaboration"
shared_with: [noizu-intellect, therobotknows.com, tobornalp.com]
---

# US-101 — Sketch and talk with a voice pair-designer that drafts ahead of me

**As** Dana, the Systems Architect,
**I want** to sketch a design (interface, component layout, ERD schema) with pen or mouse while thinking out loud with a realtime voice agent that asks clarifying questions, and have a stronger drafting layer draft ahead of me — overlaying real, constructible elements under my strokes in redline mode,
**so that** a rough spoken-and-sketched braindump becomes a reviewed, structured model in one fluid pair-design session instead of a whiteboard photo I have to re-enter by hand.

## Experience narrative

Dana opens a canvas and starts a voice session. While she drags out boxes and lines and narrates ("this is the session service, it owns the transcript store... actually make that two tables"), a low-latency conversational agent (cheap/fast realtime voice model) talks back — acknowledging, asking clarifying questions ("should transcript entries reference the raw audio segment or just text?") — without ever blocking her drawing. The rolling transcript plus canvas deltas stream through the delegator pipe to a stronger, slower drafting model that works ahead of her: beneath her sloppy strokes it lays down actual elements — straightened lines, snapped shapes, a real entity node where she scribbled a box — all rendered in redline mode as proposals, never silently replacing her ink. When she drops a comment/text stub, names it, and says aloud what it should contain, the stub populates from the transcript. She approves proposals by voice ("approve R-4"), by right-click, or in bulk, and keeps talking; ideas bounce back and forth with a virtual pair designer while her drafting is continuously augmented.

## Acceptance criteria
- [ ] Starting a canvas voice session opens a full-duplex conversation with a low-latency realtime voice agent; speech recognition and agent responses run concurrently with drawing — talking never blocks inking and inking never interrupts playback
- [ ] The voice agent converses back-and-forth: acknowledges narration, asks clarifying questions about ambiguous strokes or statements, and proposes ideas — behaving as a pair designer, not a dictation service
- [ ] The rolling transcript + canvas deltas stream through the delegator pipe to a stronger drafting-layer model that works asynchronously ahead of the user
- [ ] The drafting layer overlays proposed concrete elements aligned under/behind the user's strokes in **redline mode** — visually distinct (redline styling), non-destructive, and clearly attributed to the agent
- [ ] Every agent-proposed element carries a **construction meta-prompt** — a self-describing spec for how the element builds/renders itself — which both the user and agents can open, review, and tweak; edits re-render the element
- [ ] Stroke cleanup: near-straight lines are straightened, shapes snapped and closed, connectors routed; the user's original ink is preserved as a toggleable layer, never destroyed
- [ ] Text/note stubs: placing a comment or text block and naming it while saying what it should read populates the stub from the transcript; **both** the literal transcript excerpt and the agent's intelligent cleanup are stored, inspectable, and switchable per stub
- [ ] Every redline element displays a short speakable ID (e.g. `R-4`); approval works by voice ("approve R-4", "reject R-7"), right-click approve/reject, direct manipulation, or batch approve-all — approved elements graduate from redline to first-class model elements
- [ ] Rejections and tweaks feed back to the drafting layer within the session so subsequent proposals reflect the correction
- [ ] The session artifact persists the full literal transcript, the agent interpretation log, and canvas history — replayable and auditable after the fact
- [ ] Latency budgets: voice turn-taking feels conversational (~1s perceived); redline drafts surface within a few seconds of the motivating utterance/stroke; slower drafts arrive incrementally rather than blocking
- [ ] Degrades gracefully: works pen or mouse; with voice unavailable, a text side-channel drives the same clarify/propose/approve loop

## Notes
Flagship expression of the shared **agentic voice/visual ↔ delegator-pipe interactive collaboration** capability. The pipe pattern — cheap realtime conversational front model, transcript + context relayed to a stronger delegating/drafting layer, proposals returned as reviewable redline artifacts — is product-agnostic and shared across the portfolio:

- **therobotdrafts** (this story): voice pair-designer over the sketch/model canvas
- **noizu-intellect**: the delegator pipe itself — agent tiering, transcript relay, memory of decisions made in-session
- **therobotknows.com**: knowledge grounding — the drafting layer pulls project/domain knowledge to inform proposals and stores what was decided
- **tobornalp.com**: same interaction pattern over planning surfaces (talk through a plan while the agent drafts structured tasks/dependencies in redline)

`shared_capability`/`shared_with` frontmatter keys are introduced here as the cross-project linking convention; counterpart stories in those projects should reference back with the same `shared_capability` string. Serves Dana's P-001 JTBD of capturing live design intent as a real model; complements authoring epic stories (US-018) and annotation flows (US-038). Dual storage of literal transcript vs. agentic interpretation is a hard requirement — trust in the pair designer depends on always being able to see what was actually said.
