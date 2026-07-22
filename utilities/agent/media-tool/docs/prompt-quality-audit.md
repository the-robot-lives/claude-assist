# Prompt / Instruction Quality Audit

Status: Phase 0 baseline (2026-07-22). Open blockers fixed in code where noted.

## Instruction layers

| Layer | Location | Role |
|-------|----------|------|
| A. Prep meta-prompt | `src/prep.rs` | LLM rewrite when prompt exceeds provider limit / refine-after-eval |
| B. Static provider guidance | `src/prep.rs` `provider_prompt_guidance` | Fallback when FIM off/missing |
| C. FIM solutions | `skill/.../references/fim/solution` via `src/fim.rs` | Injected into chat system + prep |
| D. Author `prompt.system` + text | demos + real prompts | Output contract + creative brief |
| E. Skill templates / docs | `prompt-templates/*`, README, providers.md | Authoring defaults |

**Note:** Attempt 0 sends author text **verbatim** unless a provider character limit is exceeded. Prep quality still matters for long briefs, refine loops, and FIM injection on chat types.

## Type × layer inventory

| Type | A Prep channel | B Static | C FIM map | D Demo system | E Template | Severity residual |
|------|----------------|----------|-----------|---------------|------------|-------------------|
| image (raster) | RasterImage | Imagen notes | providers/imagen | none needed | partial | nit: multi-format eval primary only |
| image+svg | Svg (via text_format) | SVG notes | svg_js.md (weak) | strong (icon demo) | schema 0.3 | major: dedicated svg.md FIM missing |
| video | Video | veo/grok notes | providers/veo, grok-video | none | none | nit: document frame-eval limits |
| music | Music | Suno notes | providers/suno | none | music-abc/lilypond only | major: no semantic eval yet |
| voice | Voice (**LLM prep skipped**) | TTS notes | providers/*-tts | none | none | major: no ASR eval |
| diagram | Diagram | DSL notes | mermaid/plantuml/graphviz | strong | schema 0.3 | major: templates pin v0.3 |
| html / game | Html | HTML notes | html.md | strong | schema 0.3 | major: no visual eval |
| react-page / component | Code | Code notes | unmapped (static) | partial | react-component.md v0.3 | major: no FIM react solution |
| style-guide | Html | HTML notes | none specific | no demo | none | major: no demo |
| document | Document | Document notes | markdown.md | no demo | latex/typst templates | major: no demo |
| sfx | Music | Suno | suno | no demo | none | major: no demo |

## Cross-cutting findings

| ID | Finding | Severity | Status |
|----|---------|----------|--------|
| P0-1 | Prep used a single image-centric rule set for all types (strip hex, px, fonts, interactions) | blocker | **Fixed** — `PrepChannel` + branched rules |
| P0-2 | Voice could be LLM-rewritten when over limit | blocker | **Fixed** — `allows_llm_prep(Voice)=false` |
| P0-3 | FIM `text_format` only applied for `is_chat_type()` — broke image+svg | blocker | **Fixed** — text_format always preferred |
| P0-4 | Demos set `diagram_type` without `text_format` — FIM missed | major | **Fixed** — `effective_text_format()` in pipeline |
| P0-5 | Chat auto-select docs list multi-provider tiers; code only offers `groq-chat` | major | **Docs reconciled** (code is source of truth for auto-select; pin `service:` for others) |
| P0-6 | `docs/providers.md` status table stale (marks implemented providers as Todo) | major | **Updated** |
| P0-7 | Skill templates still schema 0.3, no eval packs | major | open (Phase B) |
| P0-8 | README `pass_threshold: 3.5` vs 0–1 scoring | major | **Fixed** |
| P0-9 | No dedicated pure-SVG FIM solution (uses svg_js.md) | major | open |
| P0-10 | Audio unscorable by eval | major | Phase B/C |

## Per-type residual checklist (for authors)

### Raster image
- [x] Prep preserves detail; hex→names correct for Imagen
- [ ] Attach style refs in more demos
- [ ] Align negative with `reject_if`

### SVG
- [x] Prep keeps hex + numeric viewBox
- [x] Demo system enforces raw SVG
- [ ] Add `svg.md` FIM (not svg_js)
- [ ] Upgrade demo to schema 0.4 + eval pack

### Diagram
- [x] Prep preserves graph structure
- [x] diagram_type → FIM via effective_text_format
- [ ] Template/demo schema 0.4 + eval
- [ ] Prefer scoring rendered SVG when present

### HTML / React / Game
- [x] Prep keeps layout/features
- [ ] Visual eval via Puppeteer (Phase C)
- [ ] Default system when author omits system
- [ ] Schema 0.4 templates

### Video / Music / Voice
- [x] Channels distinct; voice no rewrite
- [ ] Structural audio/video gates (Phase B)
- [ ] ASR / music semantic (Phase C)

## Tests locking Phase 0

- `prep::tests::*` — channel routing, hex preserve, voice no LLM prep
- `fim::tests::*` — alias map, image+svg resolution, provider maps
- `eval::tests::*` — pass/fail math, normalize scores

## Progress (Phases A–D)

| Item | Status |
|------|--------|
| Offline mock eval + unit tests | **Done** (`score_output_via_mock_eval_server`) |
| Structural audio/video | **Done** (`src/structural.rs`, hybrid default for AV) |
| Eval on all demos + document/component/sfx fixtures | **Done** |
| Skill templates schema 0.4 (key set) | **Done** (mermaid, plantuml, html, svg, react) |
| `eval.visual` HTML/SVG raster path | **Done** (Puppeteer / rsvg-convert when available) |
| Live report / make targets | **Done** (`make test-structural`, `make test-live`, `scripts/live-eval-report.sh`) |
| Dedicated pure-SVG FIM (`svg.md`) | open |
| ASR semantic voice eval | open (structural only) |
| Full multi-provider chat auto-select | open (docs match groq-chat auto) |
