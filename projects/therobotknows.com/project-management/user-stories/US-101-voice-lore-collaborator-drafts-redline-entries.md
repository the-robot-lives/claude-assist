---
id: US-101
title: "Talk through lore with a canon-grounded voice collaborator that drafts entries in redline"
slug: "voice-lore-collaborator-drafts-redline-entries"
personas: [P-007, P-003]
epic: "Agentic Voice & Visual Collaboration"
priority: "must-have"
complexity: "L"
tags: [voice, agentic, redline, knowledge-graph, canon-grounding, delegator-pipe, realtime]
shared_capability: "agentic voice/visual <-> delegator pipe interactive collaboration"
shared_with: [therobotdrafts, noizu-intellect, tobornalp.com]
---

# US-101: Talk through lore with a canon-grounded voice collaborator that drafts entries in redline

## User Story

**As a** narrative designer (P-003) collaborating with the Nova AI collaborator (P-007),
**I want to** talk through lore and worldbuilding out loud — sketching relationships and dictating detail — while a realtime voice agent asks clarifying questions grounded in my existing knowledge graph and a stronger drafting layer proposes new and updated lore entries, entity records, relationship edges, and timeline events as canon-grounded redline proposals,
**So that** a spoken worldbuilding session becomes reviewed, cited, contradiction-checked additions to my knowledge graph in one fluid pass instead of notes I have to re-enter and reconcile against canon by hand.

## Acceptance Criteria

- [ ] Given I start a voice worldbuilding session, when I speak and sketch relationships, then a low-latency realtime voice agent converses back-and-forth concurrently — acknowledging, asking clarifying questions, and proposing ideas as a pair collaborator — without blocking my speech or input.
- [ ] Given the voice agent asks clarifying questions, when my statement touches existing canon, then its questions are grounded in the current knowledge graph (e.g. "you said Mira rules the northern hold — canon says her sister does; retcon or mistake?") rather than generic dictation prompts.
- [ ] Given the rolling transcript and workspace deltas stream through the delegator pipe, when the stronger drafting layer works ahead of me, then it proposes new/updated lore entries, entity records, relationship edges, and timeline events as **redline** proposals — visually distinct, non-destructive, and clearly attributed to the agent.
- [ ] Given a redline proposal is drafted, when I inspect it, then it cites the specific knowledge-graph nodes that informed it and carries a construction meta-prompt that I and agents can open, review, and tweak; edits re-render the proposal.
- [ ] Given a proposal would contradict established canon, when the drafting layer detects the conflict, then the contradiction is flagged for my resolution rather than silently written into the graph.
- [ ] Given each redline proposal displays a short speakable ID (e.g. `R-4`), when I approve by voice ("approve R-4"), right-click, or batch approve-all, then approved proposals graduate into the knowledge graph as first-class nodes and edges.
- [ ] Given a proposal is approved, when it graduates into the graph, then **both** the literal transcript excerpt and the agent's cleaned interpretation are stored per entry, inspectable and switchable after the fact.
- [ ] Given I reject or tweak a proposal, when the correction is made, then it feeds back to the drafting layer within the session so subsequent proposals reflect the correction, and the session artifact persists the full transcript, interpretation log, and workspace history for replay and audit.

## Notes

Expression of the shared **agentic voice/visual ↔ delegator-pipe interactive collaboration** capability for the living-wiki knowledge base: a cheap low-latency conversational front model talks with the user while transcript and workspace deltas relay to a stronger drafting layer that returns reviewable redline proposals grounded in the knowledge graph. The pattern is product-agnostic and shared across the portfolio via the `shared_capability` / `shared_with` frontmatter convention. Sibling US-101 stories:

- **therobotdrafts** — voice pair-designer that drafts ahead over the sketch/model canvas (canonical sibling story).
- **noizu-intellect** — provides the underlying delegator pipe: agent tiering, transcript relay, and memory of in-session decisions.
- **tobornalp.com** — same interaction pattern over planning surfaces (talk through a plan while the agent drafts structured tasks/dependencies in redline).

therobotknows's manifestation grounds the drafting layer in canon: proposals cite the graph nodes that informed them, contradictions are flagged rather than silently written, and both literal transcript and cleaned interpretation are stored per entry. Works alongside the Nova AI-collaborator persona (P-007) and complements the Generation Engine's canon-context grounding (US-037) and source citations (US-038), the Consistency Engine's contradiction detection (US-051), and the Session Companion's note auto-extraction (US-064). Dual storage of literal transcript vs. agentic interpretation is a hard requirement — trust in the collaborator depends on always being able to see what was actually said.
