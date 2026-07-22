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

### Views

| Tab | Behavior |
|-----|----------|
| **Providers** | All providers/channels by category; filter by status (implemented / stub / FIM / local); search; scaffold YAML; scaffold+generate; FIM preview |
| **Demo types** | Curated demos grouped by media type; generate / eval / synthesize more prompts |

### Registry composition

| Kind | Source |
|------|--------|
| Media APIs | Implemented + planned stubs (`gemini`, `suno`, `veo`, …) |
| Chat APIs | `groq-chat`, `anthropic`, `gemini-chat`, `openai-chat`, `z.ai` |
| Renderers | `mermaid`, `plantuml`, `graphviz`, `puppeteer` |
| FIM channels | Every `skill/.../fim/solution/*.md` + category members (~200) |

### API surface

- `GET /api/health` — includes `providers_total` / status counts  
- `GET /api/providers?category=&status=&kind=&q=` — full registry + filters  
- `GET /api/providers/{id}` — detail + scaffold YAML + FIM preview (`media:gemini`, `fim:d3_js`, …)  
- `POST /api/providers/{id}/scaffold` — write workspace test prompt  
- `GET /api/catalog` — demo type groups  
- `GET /api/prompt?path=` — full YAML + outputs  
- `GET /api/media?path=` — safe media bytes  
- `POST /api/generate` / `POST /api/eval` / `POST /api/prompts/generate`  
- `GET /api/jobs` / `GET /api/jobs/{id}`  

Requires API keys for live generate/synth; eval needs `GROQ_API_KEY` or `MEDIA_EVAL_*` / port-forward.

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
