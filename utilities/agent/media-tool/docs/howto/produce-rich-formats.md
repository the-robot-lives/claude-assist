# How to: get correct output in niche/post-training-cutoff media formats

**Goal:** get an LLM provider to emit syntactically correct markup/code for ~190 diagram DSLs, canvas/WebGL engines, math typesetting, music notation, audio synthesis, EDA/circuit tools, and more — instead of guessing at syntax it half-remembers.
**Prereqs:** none beyond a normal chat-type prompt (`gemini-chat`, `anthropic`, `openai-chat`) — this is on by default.

## What it does

Every text-output generation (SVG, diagrams, HTML/canvas, code) is, by default, given extra
system-prompt guidance pulled from the FIM ("fill-in-the-middle") solution library at
`skill/content-media-engine/references/fim/` — matched by the prompt's declared provider/asset
type/`text_format`. This is what lets a prompt asking for, say, a WaveDrom timing diagram or a
Vega-Lite spec come back syntactically correct on the first try instead of drifting into
plausible-looking but broken markup.

It is **on by default** for every prompt run through the pipeline — you don't opt in, you'd
opt *out*.

## How to use it

1. Just declare the right `text_format` / `diagram_type` in your prompt file — the tool resolves
   guidance automatically:
   ```yaml
   output:
     formats:
       - format: mmd
   diagram_type: mermaid
   ```
2. Browse what's covered before you write the prompt:
   ```bash
   less skill/content-media-engine/references/fim/overview.md      # 8 categories, ~190 solutions
   less skill/content-media-engine/references/fim/INVENTORY.md     # full flat list
   ```
   Categories: diagram DSLs/XML, data visualization, network/graph + 3D/WebGL, geospatial +
   math/scientific, music notation + audio + ML, electronics/HDL/timing + image/video + doc
   processing.
3. Confirm the guidance is actually being injected for a given run:
   ```bash
   generate-media-prompt --dry-run --verbose demos/diagram/sample-mermaid.media.prompt
   ```
   (FIM injection happens at prep time, before the API call — `--verbose` plus a live, non-dry
   run will show the expanded system prompt.)

## Turning it off

Disable per-run when you want the raw prompt sent with no solution-specific scaffolding
(e.g. A/B-testing prep quality, or a format not in the library):

```bash
generate-media-prompt --no-fim my-prompt.media.prompt
```

or globally via environment variable (useful in CI):

```bash
export MEDIA_FIM_INJECT=0
```

**Verify:** re-run with `--no-fim` vs without on the same diagram prompt and diff the generated
output — the FIM-guided run should track the DSL's actual syntax more closely.

**Gotchas:**
- FIM guidance only fires for **text-output** (chat-provider) generations — binary providers
  (Gemini Imagen, Suno, TTS, video) don't consume it.
- A solution not present in `INVENTORY.md` gets no injected guidance; the prep step still runs,
  it just has nothing format-specific to add. Check the inventory before assuming a niche format
  is covered.
- `src/prep.rs` is what wires `fim_enabled` into the actual system prompt — if guidance seems
  missing for a covered solution, confirm the prompt's `service`/`text_format` combination
  matches how the FIM library keys its lookups (see `src/fim.rs`).
