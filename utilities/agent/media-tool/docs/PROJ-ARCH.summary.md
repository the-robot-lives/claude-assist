# Project Architecture — Summary

## Overview

media-tool generates media assets from declarative YAML `.media.prompt` files (schema v0.4). Authors declare intent (asset type, quality tier, prompt, eval criteria); the tool handles provider auto-selection, dependency-DAG ordering, generation across 13 provider APIs, markup rendering, LLM eval grading with provider fallback, and interactive refinement. Primary implementation: Rust binary `generate-media-prompt` (clap/tokio/ratatui) installed to `~/.local/bin`; legacy bash+Python engine kept as no-cargo fallback.

## Core Components

- `main.rs` — CLI entry, input resolution, dispatch
- `schema.rs` — YAML parsing, legacy v0.1–v0.3 normalization
- `dag.rs` — dependency DAG, cycle detection, Kahn's tiering
- `pipeline.rs` — orchestration, dry-run, quality→provider selection
- `providers/` — 13 implementations: image (Gemini Imagen, ZAI), music (Suno), TTS (OpenAI, ElevenLabs, Qwen), video (Grok, Veo), chat (Gemini, Anthropic, OpenAI, Groq)
- `renderers/` — Mermaid, PlantUML, Graphviz, Puppeteer (markup → visual)
- `eval.rs` — weighted-criteria vision grading (Qwen 3.6), drives provider fallback
- `refine.rs` / `prep.rs` / `validate.rs` — feedback loop, prompt expansion, SVG lint auto-fix
- `bin/` + `lib/` — legacy bash wrapper (k8-lib) and Python engine; `media-eval-port-forward` kubectl helper
- `skill/content-media-engine/` — Claude Code skill packaging; `demos/` — working examples per asset type

## Provider Architecture

Three categories dispatched via `MediaProvider` trait registry: media APIs (binary output), chat-completion APIs (text/code), and local renderers (post-generation markup → visual). New provider = trait impl + registration.

## Generation Flow

Parse/normalize → resolve depends_on DAG (cycles abort) → generate tier by tier with `${alias}` substitution (collapse: file/inline/context) → output naming/formats → optional eval grading.

## Quality Selection & Eval

`quality: low|medium|high` drives candidate provider order; each output is graded against the prompt's eval block by a hosted Qwen 3.6 vision model, with fallback to the next provider until pass or exhaustion (best kept with warning). Evaluator endpoint probed: MEDIA_EVAL_BASE_URL → LAN server → noizu.server → in-cluster lmstudio-proxy → local port-forward.

## Ecosystem Integration

`make install` → `~/.local/bin` (repo-wide make install-utilities flow); bash wrapper sources k8-lib common.sh; API keys resolve env → `.envrc.k8.dc` at `$INFRA_ROOT`; eval can use the noizu k8s cluster's lmstudio-proxy service; packaged as the content-media-engine Claude Code skill.

## Key Decisions

- Rust rewrite for single binary + TUI + async polling; Python engine as fallback only
- Declarative YAML with quality tiers instead of provider pinning
- Cross-file dependency DAG as first-class batch model
- Eval-gated generation with graceful degradation when no evaluator reachable
- Renderers as post-transforms, separate from generation providers

## Known Gaps

Post-processing actions stubbed; within-tier parallelism, inline/context collapse substitution, and several image providers still planned.
