# CLAUDE.md variants — eval corpus (file mode)

Alternative takes on the repo-root `CLAUDE.md`, varying compression level (c0–c5, see
trl-prompt-optimizer `assets/compactness-scale.md`), style methodology, and natural
language. Managed per the trl-prompt-optimizer file-mode convention, with one declared
divergence: this variants dir lives at `.claude/CLAUDE.md/` (not a sibling `.CLAUDE.md/`).

## Mechanics

- **Spec**: `../../CLAUDE.md.prompt` — key requirements, protect list, eval rubric + dataset, `pin`.
- **Live prompt**: repo-root `CLAUDE.md` is a **symlink** into this dir. Promotion/rollback =
  `ln -sfn .claude/CLAUDE.md/<slug>.md CLAUDE.md` (atomic; never copy content). The spec `pin`
  overrides auto-selection.
- **Sidecars**: every variant has `{slug}.meta.md` — style, size, loss ledger, eval scores.
- **Baseline**: `baseline.md` is the permanent level-0 control (typos intact, never edited);
  sole in-corpus recovery source for c5 drops.
- **Evals**: none run yet — all metas read "not yet run". Scoring harness is follow-up work.

## Trinity staging

All variants except `baseline` (control) and `shorthand-c2` (pristine pre-trinity live pin)
state the **Trinity Protocol** (`protocols/the-trinity-protocol.md`) as required runtime
behavior — DO NOT SILENTLY IGNORE. The live pin is deliberately pre-trinity; to take trinity
live, repoint the symlink (or `pin`) to `shorthand-trinity-c2`.

## Variants

| slug | approach | level | lossless | trinity |
|------|----------|-------|----------|---------|
| `baseline` | verbatim original (typos intact, control) | 0 | yes | — |
| `plain-english-c1` | ruthless plain-English edit, full words | 1 | yes | ✓ |
| `shorthand-c2` | abbreviations + logic symbols (⇒ ∀ ¬) — **pristine live pin** | 2 | yes | — (twin ↓) |
| `shorthand-trinity-c2` | shorthand-c2 + trinity clause | 2 | yes | ✓ |
| `structured-data-c2` | rules/facts as YAML blocks | 2 | yes | ✓ |
| `checklist-c3` | MUST-checklist in compliance order, reference after | 3 | yes | ✓ |
| `ultra-terse-min-loss-c3` | telegraphic, all facts inline (lossless floor) | 3 | yes | ✓ |
| `pointer-index-c4` | rules inline; reference → verified doc pointers | 4 | by reference | ✓ |
| `ultra-terse-lossy-c5` | telegraphic; secrets cheatsheet dropped → pointer | 5 | **lossy** | ✓ |
| `spr-priming-c5` | SPR — sparse priming cue lists | 5 | **lossy** | ✓ |
| `latex-logic-c3` | LaTeX-style formal spec, deontic operators O()/F()/P() | 3 | yes | ✓ |
| `npl-ref-c4` | NPL reference-mode: rules inline + `NPLLoad X@tier` fetches | 4 | by reference | ✓ |
| `mermaid-c3` | workflows as mermaid graphs, facts in tables between | 3 | yes | ✓ |
| `pseudo-code-c3` | typed pseudo-code module w/ guards + invariants | 3 | yes | ✓ |
| `german-c2` | German Kompakt-Stil (MUSS/NIEMALS) | 2 | yes | ✓ |
| `dutch-c2` | Dutch beknopte stijl (MOET/NOOIT) | 2 | yes | ✓ |
| `japanese-c2` | Japanese kanji-dense telegraphic (である調) | 2 | yes | ✓ |
| `classical-chinese-c3` | Classical Chinese 文言文, densest NL register | 3 | near-lossless | ✓ |
| `ithkuil-gloss-c5` | romanized Ithkuil + normative English gloss (experimental) | 5 | **lossy** | ✓ |

Protected at every level (see spec `protect`): trinity clause, session-first flow +
`Session.Create` ToolCall block, env-var non-expansion gotcha, MinIO port-forward
prerequisite, all `dc`/`secret-bucket` command syntax (verbatim English, even in
language variants).
