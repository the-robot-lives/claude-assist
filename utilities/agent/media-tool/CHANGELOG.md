# Changelog — media-tool

Milestone-based changelog (this monorepo does not version components independently).
Tags follow `utilities-agent-media-tool/<milestone>`; pre-import milestones (m1–m3)
are tagged on the original standalone-repo lineage preserved by the subtree squash.

## [Unreleased]
- Added `docs/PROJ-FAQ.md` + summary (motivation/fit/comparison/capability/caveats/trust Q&A) (2026-07-17)
- Added `docs/PROJ-HOWTO.md` + summary and `docs/howto/` (first-hour, FIM rich-format usage, common-error troubleshooting) (2026-07-17)
- Added `docs/PROJ-ARCH.md` + summary; refreshed `docs/PROJ-LAYOUT.md` and `docs/layout/src.md` (2026-07-16)

## [m6-fim-solution-library] — 2026-07-09 — tag: `utilities-agent-media-tool/m6-fim-solution-library`
Milestone summary: built out the FIM ("fill-in-the-middle") solution library — a
catalog of ~190 LLM-emittable media formats (diagram DSLs, canvas/WebGL/3D engines,
math/scientific rendering, music notation, audio synthesis, circuit/EDA tools)
with per-solution reference guides and eval scenario suites, wired into the CLI.

### Added
- `src/fim.rs` FIM subsystem plus `main.rs`/`pipeline.rs`/`prep.rs` integration
- `skill/content-media-engine/references/fim/` — categorized solution index, overview, inventory, per-solution guides
- Solution walkthrough docs (getting-started, limerick, sonnet, marketing-copy)
- 4-scenario eval `.media.prompt` suites (canonical / stress / communication / integration) per solution — several hundred prompt files
- Committed eval-run artifacts (rendered diag/svg/png/pdf outputs + metadata) for diagram solutions

### Changed
- Per-solution reference docs substantially expanded (~37k insertions across the milestone)
- README / HOW-TO updated for FIM usage

## [m5-quality-eval-gating] — 2026-06-14 — tag: `utilities-agent-media-tool/m5-quality-eval-gating`
Milestone summary: schema v0.4 — authors declare intent (type, quality tier) and
acceptance criteria; the tool owns provider choice, grades outputs against the
prompt's `eval` block via a hosted LM Studio model, and falls back across
candidate providers until one passes.

### Added
- `src/prep.rs` (prompt preparation) and `src/validate.rs` (prompt validation)
- `docs/quality-selection-and-eval.md` design doc
- `bin/media-eval-port-forward` helper for the eval-model endpoint

### Changed
- `pipeline.rs` overhauled for quality-based provider selection with eval-gated fallback
- `eval.rs` expanded (~5x) to grade outputs against declared criteria
- `schema.rs` upgraded to `.media.prompt` schema v0.4; Suno and provider registry reworked
- README, HOW-TO, demos, and skill doc updated to schema v0.4

## [m4-monorepo-import] — 2026-06-13 — tag: `utilities-agent-media-tool/m4-monorepo-import`
Milestone summary: standalone media-tool repo imported into the Noizu infra
monorepo as a squashed git subtree at `utilities/agent/media-tool/`.

### Changed
- Project root moved from standalone repo to `utilities/agent/media-tool/`; prior history preserved behind the subtree squash commit

## [m3-project-management-scaffold] — 2026-06-01 — tag: `utilities-agent-media-tool/m3-project-management-scaffold`
Milestone summary: product-planning corpus and layout docs added on top of the
working tool.

### Added
- `project-management/` — 8 user personas and 100 user stories (US-001…US-100)
- `docs/PROJ-LAYOUT.md` + summary and `docs/layout/src.md`

### Changed
- Makefile tweaks

## [m2-rust-rewrite] — 2026-05-27 — tag: `utilities-agent-media-tool/m2-rust-rewrite`
Milestone summary: the Python prototype was rewritten as a Rust CLI with a full
generation pipeline — 12 providers, local renderers, refinement loop, eval hooks —
plus demos across every supported media type.

### Added
- Rust crate: `pipeline.rs`, `schema.rs`, `refine.rs`, `eval.rs`, `dag.rs`, `attachments.rs`, `output.rs`, `ui.rs`
- Providers: Anthropic, OpenAI (chat + TTS), Gemini (image + chat), ElevenLabs, Qwen TTS, Suno, Veo, Grok video, Z.ai
- Renderers: mermaid, plantuml, graphviz, puppeteer
- `HOW-TO.md`; demo `.media.prompt` suites for image, svg, diagram, html, game, music, voice, video
- MIT-style `LICENSE`

### Changed
- Demo prompts/outputs iterated; stale generated artifacts pruned

## [m1-python-prototype] — 2026-05-26 — tag: `utilities-agent-media-tool/m1-python-prototype`
Milestone summary: initial proof of concept — a Python prompt engine and CLI that
turn declarative `.media.prompt` files into generated media, with a researched
provider catalog.

### Added
- `lib/media-prompt-engine.py` (~1.2k lines) and `bin/generate-media-prompt` CLI
- `docs/providers.md` provider catalog (heavily expanded same day)
- README, Makefile, first test `.media.prompt` fixtures
