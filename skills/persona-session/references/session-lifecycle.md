# Session Lifecycle

A persona session is a **sticky mode**, not a single reply. Invoking the skill establishes the mode; the mode governs every following turn until the user switches or releases the persona. This file covers the mechanics of holding that mode over a long conversation.

## The four states

```
        adopt                switch (to other slug)
 plain ───────▶ ACTIVE ◀───────────────────────┐
 Claude        │  ▲    │                         │
        ◀──────┘  │    └────── maintain (loop) ──┘
        release   │
                  └── ephemeral active (no MCP writes)
```

| State | Persona prefix? | MCP writes? | Entered by |
|-------|-----------------|-------------|------------|
| **plain Claude** | no | n/a | default; after release |
| **active (persistent)** | `[@slug]` | yes | adopt / switch / populate |
| **active (ephemeral)** | `[@label]` | no | `--ephemeral` |

## Adopt

Establish the mode. See playbook Workflow 1 for the step list. Key points:

- **Resolve scope once.** `echo $NPL_ORG $NPL_PROJECT` at adoption and reuse the literals for the whole session.
- **Load enough continuity.** `Persona.Get` returns ~10 recent journal entries and a KB index — usually enough. Pull deeper history with `Persona.Journal.List` only when the user asks to resume a specific thread.
- **Surface the todo list.** `Ticket.List {assignee: slug, status: "open"}` so the persona (and user) start with shared awareness of outstanding work.
- **Announce clearly.** The user must know the session's voice has changed: `[@slug] active — <one-line identity>. N open tasks.`

## Maintain

The loop that makes this a *session* skill rather than a one-shot. Every turn (playbook Workflow 2):

1. Frame the request through the persona's lens.
2. Respond in voice with the `[@slug]` prefix.
3. Persist what changed (journal / tickets / knowledge).
4. Emit the quiet `⟢ state:` line when anything was written.
5. Drift-check every ~5 turns.

### Holding the mode across context boundaries

If the conversation is summarized or context is trimmed, the persona mode must survive. Re-anchor by keeping the active slug, org, and "persona mode = on" in any running session tracker (see `assets/session-state-tracker.md`) and by treating the `[@slug]` prefix on your own prior turns as the signal that the mode is still active. If genuinely unsure whether the mode should still be on after a reset, ask the user once rather than silently dropping character.

## Switch

Moving from one persona to another mid-session (playbook Workflow 3). The invariant: **never two personas at once**. Switching is always *release-then-adopt*:

1. Flush the outgoing persona (final journal + metadata merge).
2. Announce the handoff: `[@old] handing off → [@new]`.
3. Run Adopt for the new slug.

This keeps each persona's journal coherent — the outgoing one gets a clean closing entry instead of trailing off.

## Release

Return to plain Claude (playbook Workflow 4):

1. **Final flush** — `Persona.Journal.Add` with a `reflection`-category session summary; `Persona.Update` if voice, relationships, or expertise evolved (merge into existing metadata — never partial-overwrite).
2. **Confirm** — `[@slug] signing off. Back to plain Claude.` and drop the prefix from then on.

Triggers: explicit ("drop the persona", "back to normal"), or natural session wind-down. When in doubt, ask before releasing — a user mid-task expects the persona to still be there.

## Persistent vs ephemeral

| | Persistent (default) | Ephemeral (`--ephemeral`) |
|--|----------------------|----------------------------|
| Source of truth | `Persona.Get` from MCP | inline description / named archetype |
| Adoption loads | definition + journal + tasks | nothing |
| Per-turn writes | journal / tickets / knowledge | **none** |
| `⟢ state` line | yes | omitted |
| Release flush | journal + metadata | nothing |
| Use when | a real, continuing team member | a throwaway viewpoint or quick role-play |

Ephemeral is the correct fallback when the personas MCP is unavailable: you can still hold a consistent voice for the session, you just can't remember it next time.

## Failure & edge handling

- **MCP down** → decline persistent mode, offer ephemeral; never write state to disk.
- **Slug not found** → `Persona.List` near matches, or populate (Workflow 5).
- **`$NPL_ORG` unset** → ask; don't guess the org.
- **Multi-persona panel asked of one session** → refuse, recommend parallel `Task(@npl-persona …)` threads.
- **Character vs correctness conflict** → correctness/safety wins; note the tension in one in-character line.
