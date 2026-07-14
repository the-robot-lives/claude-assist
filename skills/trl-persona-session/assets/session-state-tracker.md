# Session State Tracker

A lightweight running scratch for the active persona session. Keep it current so the persona mode survives a context summary or reset (see `references/session-lifecycle.md` → "Holding the mode across context boundaries"). Not persisted to MCP — this is in-session working memory only.

---

## Active persona

| | |
|--|--|
| **mode** | `active` / `ephemeral` / `released` |
| **slug** | `____` |
| **organization** | `____`  _(resolved literal)_ |
| **project** | `____` |
| **adopted at turn** | `__` |
| **persistent?** | yes / no _(ephemeral = no MCP writes)_ |

## Voice anchor _(from metadata.voice — re-read on drift)_

- lexicon: `____`
- patterns: `____`
- OCEAN tilt in one line: `____`  _(e.g. "blunt, exhaustive, calm")_

## Neuro-endocrine state _(emulated Monitor — update every turn)_

| signal | baseline | current | last moved by |
|--------|----------|---------|---------------|
| cortisol (stress/urgency) | `0._` | `0._` | `____` |
| dopamine (reward) | `0._` | `0._` | `____` |
| oxytocin (trust) | `0._` | `0._` | `____` |
| serotonin (stability) | `0._` | `0._` | `____` |
| **VAD mood** | — | `V±_._ A_._ D_._` | this turn |

## Open tasks _(from Ticket.List {assignee: slug})_

| ticket | title | status |
|--------|-------|--------|
| `____` | `____` | `____` |

## Pending state writes _(this turn — clear after persisting)_

- [ ] journal entry: `____` (category: ____)
- [ ] ticket: create / update `____`
- [ ] knowledge: `____`
- [ ] memory (salient?): `Memory.Remember` `____` (content_type: ____)
- [ ] metadata merge: `____`

## Drift log _(every ~5 turns)_

| turn | voice holding? | correction applied |
|------|----------------|--------------------|
| `__` | yes / no | `____` |

## Release checklist

- [ ] final journal flush (category: reflection)
- [ ] metadata merge if voice/relationships/expertise evolved
- [ ] reusable learnings → knowledge base
- [ ] prefix dropped, "back to plain Claude" confirmed
