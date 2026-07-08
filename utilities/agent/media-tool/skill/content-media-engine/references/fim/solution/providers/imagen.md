# Google Imagen — natural-language image generation with best-in-class text rendering

Google's Imagen family is a text-to-image model served through the Gemini API (`generativelanguage.googleapis.com`). It reads **plain descriptive English**, not token-weighted tag soup — think of the prompt as a short design brief. Imagen 4 is the current generation and is notably strong at rendering legible in-image text (posters, packaging, signage), long descriptive prompts, and photoreal scenes. Access is paid API only (no open weights). In media-tool this is the **only implemented image provider**, wired as `service: gemini`.

**Current model**: Imagen 4 (`imagen-4.0-*`, GA mid-2025) — Fast / Standard / Ultra tiers. **Access**: paid API (Gemini API key).
**Wired in media-tool as**: `service: gemini` (see `src/providers/gemini.rs`). Reference-image edits route to `gemini-2.5-flash-image` via the `generateContent` endpoint.

> Version note (web-verified 2026-07): Imagen 4 is the shipping generation exposed as `imagen-4.0-generate-001` (standard), `imagen-4.0-fast-generate-001` (fast), and `imagen-4.0-ultra-generate-001` (ultra). Ultra's headline gain is text rendering. Sources: [Gemini API — Imagen docs](https://ai.google.dev/gemini-api/docs/imagen), [Imagen 4 prompting guide](https://www.atlabs.ai/blog/imagen-4-prompting-guide), [Imagen 4 Ultra overview](https://www.mindstudio.ai/blog/what-is-imagen-4-ultra-google).

## How This Model Reads Prompts

Imagen is a **natural-language** model. Write full descriptive sentences or a tight comma-light brief — NOT weighted tags. There is **no `(word:1.3)` weighting, no LoRA, no `<...>` syntax**; anything like that is treated as literal text and can leak into the image.

- **Ideal length**: one to three sentences (~15–60 words). It handles long prompts gracefully — up to the 4000-char hard cap enforced by media-tool — but front-load what matters.
- **What it weights most**: the **subject stated first**. Google's guidance is subject → context/environment → style/lighting/detail. Put "a graffiti-style fox mascot" before "on a rain-slicked alley wall at dusk, cinematic."
- **Ordering guidance**: `subject → composition/shot → environment → lighting → style/medium → in-image text (if any)`.
- **Emphasis without weights**: repeat or elaborate the important element in natural language ("a *single, prominent* red maple, its canopy filling the upper third"), rather than reaching for a weighting operator it doesn't support.

## Prompt Grammar / Syntax

There is no special operator grammar. Control happens through **descriptive vocabulary** plus a few **API parameters** (not in-prompt flags). The knobs media-tool exposes:

- **Aspect ratio** — API parameter `aspectRatio` (top-level `aspect_ratio` option), one of `1:1 | 3:4 | 4:3 | 9:16 | 16:9`. Do NOT write `--ar 16:9` in the prompt text; it will render as literal characters.
- **In-image text** — quote it explicitly: `the words "GRAND OPENING" in bold sans-serif`.
- **Safety / people** — `safetyFilterLevel`, `personGeneration` (see Integration Notes).

Minimal effective prompt:

```text
A studio product photo of a matte-black ceramic coffee mug on a light oak table,
soft window light from the left, shallow depth of field, minimalist, high detail.
```

In-image text prompt:

```text
A vintage travel poster of the Swiss Alps at golden hour, art-deco style,
with the title "GRINDELWALD" in clean bold serif letters across the bottom third.
```

## How-To (worked recipes)

### How to render clean, correctly-spelled in-image text
Quote the exact string, keep it short, and say where it goes. Imagen 4 (Ultra especially) is strong here but degrades past ~25 characters per phrase and 2–3 phrases per image.
```text
A minimalist café menu board, chalk lettering on dark slate, centered heading
"TODAY'S SPECIALS" with three short lines below, warm tungsten lighting.
```
Note: keep each phrase < 25 chars; for brand-grade kerning, still overlay type in a design tool afterward.

### How to steer style without washing out the subject
Name the subject concretely first, then attach the style as a trailing clause so it modifies rather than replaces the subject.
```text
A portrait of an elderly fisherman mending a net, weathered hands in focus,
rendered as a soft oil painting with visible brushstrokes and muted earth tones.
```
Note: subject-first ordering keeps the face/composition anchored while the style clause colors it.

### How to hit a specific composition / camera framing
Use photographic language — shot size, lens feel, angle, depth of field — instead of trying to weight elements.
```text
A low-angle wide shot of a lone hiker on a ridgeline against a vast sky,
35mm look, deep depth of field, backlit rim light, cinematic dawn palette.
```
Note: "wide shot / close-up / low-angle / overhead" are the reliable framing levers.

### How to set aspect ratio correctly
Pass it as the API parameter, never in the prompt string.
```yaml
# .media.prompt front-matter
aspect_ratio: "16:9"
```
Note: media-tool maps `aspect_ratio` → the Imagen `aspectRatio` parameter; supported values are `1:1, 3:4, 4:3, 9:16, 16:9` (default `1:1`).

### How to place a subject in a described environment
Give the subject, then a concrete environment clause with light and time-of-day; Imagen composites them coherently.
```text
A red vintage bicycle leaning against a pastel-blue Lisbon townhouse wall,
morning light, cobblestone street, potted geraniums, warm and inviting.
```
Note: one environment, one light source — layering three lighting states confuses the scene.

## Do's and Don'ts

### ✅ Do
- Write **descriptive natural-language sentences**; lead with the subject.
- **Quote in-image text** verbatim and keep phrases short.
- Specify **shot, lighting, medium/style** in plain words.
- Pass **aspect ratio and safety settings as parameters**, not prompt text.
- Add sensory/material detail ("matte", "brushed steel", "soft window light") to lift realism.

### ❌ Don't
- Don't use `(word:1.3)`, `[word]`, `<lora:...>`, or `--flags` — Imagen has no such grammar; they become artifacts or literal text.
- Don't stuff a comma-separated tag list (Danbooru-style) — that's a Stable Diffusion habit; Imagen reads prose better.
- Don't cram >3 text phrases or long paragraphs of embedded copy — spelling and layout break down.
- Don't stack contradictory lighting/times of day in one prompt.
- Don't rely on a negative-prompt operator (see below) — it's not a first-class knob here.

## Negative Prompts / Exclusions

Imagen 4 does **not** expose a reliable general-purpose negative-prompt field the way Stable Diffusion does. (Earlier Imagen API revisions had a `negativePrompt` parameter that has been de-emphasized/removed for newer models — treat it as unavailable and web-verify before relying on it.) media-tool's `negative_prompt` field is **not forwarded** to the Imagen `predict` call.

Practical exclusion strategy: **state what you want in the positive prompt** ("a clean empty desk, nothing on the surface") rather than listing what to avoid. Phrasing the desired positive is more effective than negation for this model.

## Styling & Control

- **No samplers / steps / CFG** exposed — Imagen abstracts the diffusion process; there is no `steps`, `sampler`, or `cfg_scale` knob.
- **No user-set seed** in the media-tool wiring — outputs vary run to run; generate a small batch and pick.
- **Quality tiers via model choice**: `fast` (speed/cost) → `standard` → `ultra` (max fidelity + best text). media-tool selects these by `Quality::Low/Medium/High`.
- **Reference images**: attachments switch to the `generateContent` endpoint on `gemini-2.5-flash-image` (a.k.a. "Nano Banana"–class editing), enabling instruction-style edits and subject conditioning from supplied images.
- **Style control** is purely lexical: name the medium ("watercolor", "35mm film photo", "isometric 3D render", "flat vector illustration").

## Aspect / Resolution / Duration Constraints

- **Aspect ratios**: `1:1` (default), `3:4`, `4:3`, `9:16`, `16:9`. No arbitrary ratios.
- **Resolution**: model-managed (roughly 1K-class output; Ultra tier is higher fidelity). Not a user parameter in this wiring — upscale downstream (e.g. `sharp`) if you need larger.
- **Prompt length**: hard cap **4000 characters** (media-tool `constraints("gemini")`). Practical sweet spot is far shorter.
- **Duration**: N/A — still images only.

## Common Pitfalls & Troubleshooting

- **Weighted/tag-style prompts underperform** — a prep step tuned for SD will hurt Imagen. Convert tags to prose.
- **In-image text garbles** when phrases are long, numerous, or stylized script — shorten, reduce count, prefer clean sans/serif.
- **`personGeneration` / `safetyFilterLevel` block outputs** — realistic people (esp. minors) can be filtered; a `400` or empty `predictions` array often means a content-policy block, not a syntax error (see `gemini.rs` handling of empty predictions).
- **`400 Bad request`** usually = malformed parameter (bad `aspectRatio` value) or over-long prompt.
- **`401/403`** = bad/missing `GEMINI_API_KEY` (the provider bails with that hint).
- **Determinism**: no seed control here → don't expect reproducible frames; script a small N and curate.
- **LLM-prep trap**: an over-eager prep agent may inject SD negatives or `--ar` flags — strip those; route aspect ratio to the parameter instead.

## Integration Notes (media-tool specific)

- **Service id**: `service: gemini` → `GeminiProvider` (`src/providers/gemini.rs`).
- **Env var**: `GEMINI_API_KEY` (`api_key_env("gemini")` in `src/providers/mod.rs`).
- **Models** (from `candidates_for` / `default_model`): `imagen-4.0-fast-generate-001` (Low), `imagen-4.0-generate-001` (Medium/default), `imagen-4.0-ultra-generate-001` (High).
- **Endpoints**: no attachments → `…/models/{model}:predict` (Imagen); with attachments → `…/models/{generate_content_model}:generateContent` (default `gemini-2.5-flash-image`).
- **Top-level options read**: `aspect_ratio` → `aspectRatio`.
- **`provider_options` keys honored** (see the `match` in `generate_predict`): `safety_filter_level` → `safetyFilterLevel`; `person_generation` → `personGeneration`; and `generate_content_model` (overrides the edit model when attachments are present). Other keys are ignored.
- **Not forwarded**: `negative_prompt` (unused for Imagen), `duration_seconds` (video only), samplers/steps/seed (not modeled).
- **Prompt char cap**: `4000` (`constraints("gemini").max_prompt_chars`).
- **Retry/backoff**: 3 attempts, exponential backoff on `429`; `400` fails fast with a body preview; `401/403` aborts with a `GEMINI_API_KEY` hint.

## See Also
- Sibling forward-looking image providers: [`stable-diffusion.md`](./stable-diffusion.md), [`flux.md`](./flux.md), [`midjourney.md`](./midjourney.md)
- Use-case guidance: [`../use-case/media-processing.md`](../use-case/media-processing.md), [`../use-case/creative-animation.md`](../use-case/creative-animation.md)
- Provider source: `src/providers/gemini.rs`, wiring in `src/providers/mod.rs`
