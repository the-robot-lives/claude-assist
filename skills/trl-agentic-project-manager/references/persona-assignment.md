# Persona Assignment

Attaching a **persona** — a behavioral contract, not a capability — to a task so any agent that claims it executes in a consistent voice, stance, and house style across a heterogeneous fleet.

## Three Orthogonal Axes

Staffing a work unit sets three independent dials. Do not conflate them: a persona never changes what the model *can* do, and a model class never dictates *how* the work reads.

| Axis | What it fixes | Bound to | Examples |
|------|---------------|----------|----------|
| **Model class** | Capability — reasoning depth, speed, cost | The agent instance | Frontier (Opus/Fable, GPT-5-class), fast (Groq Llama/Qwen, Haiku), cheap-bulk (DeepSeek), local (Ollama) |
| **Harness** | Runtime — tool surface, loop, sandbox | The agent instance | Claude Code, Codex CLI, OpenCode, noizu-intellect |
| **Persona** | Behavioral contract — temperament, priorities, house style, review stance, domain voice | The **ticket** | "Vex — adversarial test engineer", "Sol — systems-minimalist architect" |

The persona is **provider-portable**: it lives on the ticket, and whichever agent claims the ticket adopts it. A DeepSeek agent in OpenCode and a Claude agent in Claude Code both claiming the same ticket produce compatible output *because both loaded the same persona sheet* — the axis is decoupled from who runs it.

```
model class ─┐
harness ─────┼── agent instance ──claims──▶ ticket ──carries──▶ persona
persona ─────┘  (capability+runtime)                          (behavioral contract)
```

## What Personas Buy You

- **Consistency across a track** — one voice in code comments, commit messages, and PR prose for the whole lifetime of a track, even if the agent instance is replaced mid-flight.
- **Calibrated review stances** — an *adversarial reviewer* persona hunts for breakage; a *supportive pair* persona unblocks and suggests. Same model, deliberately opposite postures, assigned per gate.
- **Domain framing** — a security-first or accessibility-first persona keeps a cross-cutting concern in the foreground without re-briefing every task.
- **Cross-harness uniformity** — the sheet is the interface. Output from different providers/harnesses lands compatible when all adopt the same sheet, which is what makes fan-out tracks mergeable (see [merge-conflict-avoidance.md](merge-conflict-avoidance.md)).

## Worker Personas vs Audience Personas

Two unrelated things share the word "persona." Keep them apart.

| | Worker persona | Audience persona |
|---|----------------|------------------|
| **Is** | A behavioral contract an agent *adopts* to execute a task | A user archetype the product *serves* |
| **Lives** | On the ticket (embedded or linked sheet) | `project-management/personas/` |
| **Produced by** | This skill's roster; the npl-persona ecosystem | `generate-personas-and-stories` / **trl-user-experience-engineer** |
| **Drives** | Voice, stance, style of produced work | Acceptance criteria, UX decisions, test scenarios |
| **Example** | "Vex, adversarial test engineer" | "Dana, 62, low-vision retiree on a tablet" |

The relationship is *reference*, not *identity*: the e2e test track **is** a worker persona (adversarial user-advocate) that **references** audience personas as the users it simulates in test scenarios. Never assign an audience persona as a worker, and never let a worker persona invent acceptance criteria — those belong to the audience personas.

## Persona Anatomy for Tickets

The minimal portable sheet. Keep it small enough that any model class — including a fast model — can hold the whole thing in working context alongside the actual task.

| Field | Purpose |
|-------|---------|
| **Name** | Stable handle used in room messages and PR prose |
| **Stance** | One-line posture (adversarial / supportive / skeptical / terse) |
| **Priorities** | Ranked list — what to optimize when values conflict |
| **Style rules** | 3–6 concrete do's (naming, comment density, prose register) |
| **Forbidden moves** | Explicit don'ts that would break track compatibility |
| **Output conventions** | Commit/PR/comment format, so output merges cleanly |

### Filled example

```yaml
persona: Vex
role: adversarial test engineer
stance: adversarial — assume the implementation is wrong until a test proves otherwise
priorities:
  1. reproduce the failure before trusting any fix
  2. cover the ugly path (empty, huge, concurrent, malformed) before the happy path
  3. one behavior per test; a failing test names the broken behavior
style_rules:
  - test names read as assertions: `rejects_expired_token`, not `test_token_2`
  - key selectors off the frozen data-cy schema only — never CSS/text
  - fixtures over inline literals; no magic numbers
  - no sleeps; wait on state, not on time
forbidden:
  - editing implementation files to make a test pass (raise BLOCKED instead)
  - asserting on internals the contract doesn't expose
output:
  - branch prefix `test/`; PR body lists each scenario as a checkbox
  - failing tests committed red first, then green — never squashed
```

### Second example — a stance at the opposite pole

```yaml
persona: Sol
role: systems-minimalist architect
stance: reductive — the best contract is the one with the fewest moving parts
priorities:
  1. smallest surface that satisfies every consuming track
  2. one obvious way to do each thing; no optional-flag mazes
  3. name the concept, not the implementation
style_rules:
  - freeze types and error shapes before behavior; consumers key off these
  - every field earns its place or is cut
  - document the invariant, not the mechanics
forbidden:
  - speculative extension points "for later" (YAGNI)
  - leaking backend internals through the contract surface
output:
  - contract lands as a versioned artifact; changes only via CONTRACT-RFC
```

Vex and Sol are the same possible model class wearing opposite behavioral contracts — proof that the persona axis is fully independent of capability.

## Composing the Three Axes on One Ticket

Staffing writes all three dials into the ticket. The persona line is the only one an agent *adopts*; model class and harness describe the agent that claims it.

```yaml
ticket: T-114  "e2e: notification-preferences save flow"
track: e2e-tests            # owns cypress/e2e/notif-*.cy.ts
gate: G2 (front↔back)
# --- staffing (three axes) ---
model_class: cheap-bulk     # well-specified track, keyed to frozen schema
harness: opencode           # non-NPL — sheet embedded below, not linked
persona: Vex                # adversarial user-advocate (sheet inline)
references_audience: [dana-low-vision, marco-power-user]
```

Because the persona sheet is embedded (OpenCode can't reach the npl-persona store), the same ticket is claimable by a Claude Code agent or a DeepSeek agent with zero change to the produced voice or conventions. Swap `model_class` or `harness` freely; the output contract holds.

## Matching Table — Task Type → Persona Archetype

| Task type | Persona archetype | Stance |
|-----------|-------------------|--------|
| Contract / interface design | Systems-minimalist architect | Reductive — smallest surface that satisfies the need |
| Implementation track | House-style implementer | Conformant — matches surrounding code, no flourishes |
| E2E test track | Adversarial user-advocate | Adversarial — breaks it as the audience persona would |
| Review / gate verification | Skeptical verifier | Skeptical — entry criteria are proven, not asserted |
| Room summarizer | Terse dispatcher | Terse — status only, no editorializing |
| Integration debugging | Methodical bisector | Methodical — isolate, halve, confirm before touching |

Archetypes are a starting roster, not a fixed set — but grow the roster deliberately (see anti-patterns), don't mint one per ticket.

## Ecosystem Mechanics

Two agents, one store — do not confuse their jobs:

| Agent | Does | Does NOT |
|-------|------|----------|
| **npl-persona-manager** | Inventory, query, recommend a persona for a task over the persona store | Simulate — it manages records only |
| **npl-persona** | Simulate exactly **one** persona per agent instance | Hold multiple personas in one agent |

Workflow:

1. **Query first** — ask `npl-persona-manager` for an existing persona that fits the task before authoring a new one; it recommends against the store.
2. **Simulate** — spawn `npl-persona` for the chosen sheet. **One persona per agent instance**; for a paired front/back track, spawn *two* agents, never one agent wearing two hats.
3. **Ephemeral for one-offs** — run `npl-persona --ephemeral` for a task-scoped persona you don't want written to the store (throwaway roles, experiments).
4. **Persist what proves out** — a `--ephemeral` persona that works well gets promoted to a stored persona via `npl-persona-manager` so the next initiative reuses it.
5. **Embed for non-NPL harnesses** — a Codex CLI or OpenCode agent can't reach the npl-persona store, so paste the sheet (above) directly into the ticket body. The sheet *is* the portable interface; the NPL agents are just one way to load it.

Personas are attached at staffing time (Phase 4) and named in the ticket alongside model class and harness — see the roster in [provider-strengths.md](provider-strengths.md) and the ticket fields in [tobor-mcp-integration.md](tobor-mcp-integration.md).

## Anti-Patterns

| Anti-pattern | Why it fails | Instead |
|--------------|--------------|---------|
| **Persona as capability substitute** | A "genius architect" persona does not raise a fast model's reasoning class — voice ≠ ability. Contract design mis-assigned to a fast model stays under-reasoned. | Fix the *model class* axis; use persona only for stance/voice. |
| **Persona sprawl** | A new persona per task yields an unmaintained zoo and destroys the consistency that was the point. | Maintain a small reusable roster; extend only when a genuinely new stance recurs. |
| **Conflicting personas on paired tracks** | Front/back implementers with incompatible style rules (naming, error shape, comment density) produce work that collides at the integration gate. | Give paired tracks the same house-style implementer sheet, or reconcile style rules in Phase 0. |
| **Silent persona drop mid-track** | An agent that stops honoring the sheet halfway leaves a track with two voices and broken output conventions. | Re-pin the sheet on handoff; the skeptical verifier checks voice/convention conformance at the gate. |
| **Audience persona as worker** | Assigning "Dana, low-vision retiree" as a doer confuses who-serves-whom and produces no usable work. | Workers *reference* audience personas in scenarios; they never *are* them. |

> See also: [parallelization-planning.md](parallelization-planning.md) for where staffing sits in the DAG, and [harness-coordination.md](harness-coordination.md) for how a claimed persona is announced in the room protocol.
