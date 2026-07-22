# Testing media-tool

## Layers

| Layer | Command | Network | Purpose |
|-------|---------|---------|---------|
| L0/L1 unit | `cargo test` / `make test-unit` | none | Prep, FIM, eval math, mock eval server, structural |
| L2 dry-run | `make test` | none | Unit + plan demos without API calls |
| L2 structural report | `make test-structural` / `make report` | none | ffprobe probes on demo AV outputs |
| L3 live | `make test-live` / `TYPE=image make test-live` | keys | Generate demos + report under `tmp/live-eval/reports/` |
| Lab UI | `make lab` | optional | Interactive generate/view/eval |

## Quick start

```bash
cd utilities/agent/media-tool
cargo test
make test          # cargo test + dry-run demos/
make lab           # open http://127.0.0.1:8787 test lab UI
```

## Test lab (web UI)

Interactive app with **full provider/channel registry** (media APIs, chat LLMs,
renderers, and every FIM solution — **100+ entries**), plus demo-type browsing,
generate, preview, eval, and scaffold fixtures.

```bash
# From package root
cargo run -- lab
cargo run -- lab --port 9090 --no-open
cargo run -- lab --demos ./demos --workspace ./tmp/live-eval

# Or
make lab
make lab PORT=9090
```

### UX model (map → generator → workspace)

Landing is an **expandable graph**, not a flat vendor list:

1. **Expand** a root section (Media generation · Formats & libraries · Renderers)  
2. **Drill** into a domain (e.g. Music notation, Diagrams DSL, JS charting)  
3. **Click a generator** (lilypond, mermaid, image, voice, …)  
4. **Workspace**: Generate example prompt → Process prompt → View media → Eval  

Quality low/medium/high drives **auto provider selection** for media kinds. FIM
channels set `text_format` / guidance; chat model is still auto-selected.

Search on the map filters the full generator set by name.

| Surface | Behavior |
|---------|----------|
| **Map** | Hierarchical expand/collapse + search hits |
| **Workspace** | Scaffold prompt, process, dry-run, eval, preview |
| **Auto path bar** | Ordered candidates for current quality (media kinds) |

### API surface

- `GET /api/graph` — **primary**: hierarchical map (sections → generators)  
- `GET /api/kinds` — flat kinds (compat)  
- `GET /api/health` — readiness + registry counts  
- `GET /api/catalog` / `GET /api/prompt` / `GET /api/media`  
- `POST /api/generate` — `{ path, quality?, force?, no_eval?, dry_run? }`  
- `POST /api/providers/{id}/scaffold` — example prompt for a channel  
- `POST /api/prompts/generate` / `POST /api/eval`  
- `GET /api/providers…` — full flat registry (tooling)  
- `GET /api/jobs/{id}`  

Requires API keys for live generate; eval needs `GROQ_API_KEY` or `MEDIA_EVAL_*` / port-forward.

### Settings (LLM for example prompts)

**Settings** in the lab UI configures the model used for *Generate example prompt*.

Default (queue-populator style):

| Field | Default |
|-------|---------|
| Provider | `groq` |
| Model | `openai/gpt-oss-120b` |
| Base URL | `https://api.groq.com/openai/v1` |
| API key | `env: GROQ_API_KEY` |

Persists to `tmp/live-eval/settings.json` (workspace). Supports `env: VAR_NAME` like
OSX Queue Populator / Timely vision settings.

```bash
GET  /api/settings
GET  /api/settings/llm-meta    # provider dropdown + defaults
PUT  /api/settings             # { "llm": { provider, model, base_url, api_key } }
POST /api/settings/test-llm    # ping chat/completions
```

## What unit tests cover (Phase 0/A)

- **prep**: `PrepChannel` routing (raster vs svg vs voice vs chat), hex-preserving SVG rules, voice disallows LLM prep, instruction assembly
- **fim**: text_format aliases, image+svg resolution, provider solution maps
- **eval**: `EvalScore::passes`, 0–10 → 0–1 normalization, strip think/fences

## Dry-run demos

```bash
cargo run -- --dry-run --verbose demos/
```

Requires no API keys. Validates YAML parse, DAG, candidate selection display.

## Live eval (manual until Makefile target lands)

```bash
mkdir -p tmp/live-eval
# Copy or re-point prompts; do not overwrite curated demo binaries by default.
generate-media-prompt --verbose path/to/prompt.media.prompt
```

Eval endpoint resolution: see [quality-selection-and-eval.md](quality-selection-and-eval.md).

Helper: `bin/media-eval-port-forward` for in-cluster `lmstudio-proxy`.

## Related docs

- [prompt-quality-audit.md](prompt-quality-audit.md) — instruction layer review
- [eval-criteria-catalog.md](eval-criteria-catalog.md) — recommended `eval` packs
- [quality-selection-and-eval.md](quality-selection-and-eval.md) — runtime eval design
