# FLUX.1 — Black Forest Labs' natural-language diffusion / instruction-edit family

FLUX.1 is Black Forest Labs' text-to-image family (from the original Stable Diffusion authors). It reads **long, natural-language prompts** — closer to Imagen than to weighted-tag Stable Diffusion — and is prized for prompt adherence, coherent hands/anatomy, and legible text. The line spans open-weights variants you self-host and a paid API. **Kontext** adds true instruction-based image editing ("change the jacket to red, keep everything else").

**Current models**: `FLUX.1 [dev]` (open-weights, guidance-distilled), `FLUX.1 [schnell]` (open, Apache-2.0, few-step/fast), `FLUX.1 [pro]` (API-only, top quality), and **`FLUX.1 Kontext [dev/pro/max]`** (May 2025, image editing + generation). **Access**: open weights (dev/schnell) + paid API (pro/Kontext).
**Wired in media-tool as**: **NOT YET WIRED (forward-looking)** — no `src/providers/flux.rs`. This file prepares prompt guidance for a future integration.

> Version note (web-verified 2026-07): FLUX.1 Kontext shipped May 2025 as a multimodal generate-and-edit model; prompt cap commonly cited at **512 tokens**. dev's official guidance/CFG band is **1.5–5**. Sources: [FLUX.1 Kontext guide](https://www.promptus.ai/blog/flux-1-kontext-ai-image-editor-complete-guide-2025), [FLUX prompting guide (dev & schnell)](https://skywork.ai/blog/flux-prompting-ultimate-guide-flux1-dev-schnell/), [ComfyUI FLUX.1 Kontext guide](https://comfyui-wiki.com/en/tutorial/advanced/image/flux/flux-1-kontext).

## How This Model Reads Prompts

FLUX is a **natural-language** model. Write descriptive sentences; it parses grammar and spatial relationships well. It does **not** use `(word:1.3)` weighting or `<lora:...>` in the base prompt the way SD does — express emphasis in words ("with strong emphasis on the glowing lantern").

- **Ideal length**: one detailed sentence to a short paragraph. FLUX handles long prompts (up to ~512 tokens) better than SD, but rambling dilutes focus.
- **What it weights most**: overall semantic coherence rather than leading tokens. Describe the scene as a whole; it composes relationships (X behind Y, held in the left hand) reliably.
- **Ordering guidance**: `subject → action/pose → environment → lighting/mood → style/medium → camera`. For Kontext **edits**, lead with the **instruction verb** ("Replace…", "Add…", "Change the color of…") and explicitly say what to keep.
- **Emphasis without weights**: natural phrases — "focus on", "with emphasis on", "prominently featuring".

## Prompt Grammar / Syntax

FLUX's surface is mostly plain language plus a few real levers:

- **Guidance scale (CFG-like)**: `dev` official range **1.5–5** (a common sweet spot is ~2.5–3.5). Higher = stronger prompt adherence, lower realism; lower = more natural texture.
- **`schnell` caveat**: it is timestep-distilled — run **1–4 steps**, guidance effectively **~0 / disabled**. Don't apply dev-style CFG to schnell.
- **LoRA (open dev/schnell)**: applied by the runtime/graph (ComfyUI node, Diffusers `load_lora_weights`, or a UI `<lora:...>` if the frontend supports it) — it's a **loader-level** control, not native base-prompt grammar. Trigger words go in the natural-language prompt.
- **Kontext edit instructions**: imperative natural language — `Change the car color to matte black, keep the background and lighting unchanged.`

Minimal generation prompt (dev/pro):
```text
A weathered lighthouse keeper in a yellow raincoat stands on rocks as a storm
breaks behind him, sea spray backlit by the beam, moody cinematic photography,
shallow depth of field, 35mm.
```
Minimal Kontext edit (with a reference image):
```text
Replace the daytime sky with a dramatic sunset, keep the building, people,
and foreground exactly the same.
```

## How-To (worked recipes)

### How to write a strong generation prompt (dev/pro)
Describe subject, action, setting, light, and medium in one coherent paragraph — no tag lists, no weights.
```text
An overhead flat-lay of an artist's wooden desk: scattered watercolor tubes,
a half-finished botanical painting, brushes in a jar, warm afternoon light
raking across the grain, crisp focus, editorial photography.
```
Note: keep it one scene; FLUX rewards descriptive cohesion over keyword stuffing.

### How to make a precise, non-destructive edit with Kontext
Lead with the change verb and name what must stay fixed — Kontext edits only the requested region.
```text
Change the woman's blazer from gray to deep burgundy. Keep her face, hair,
pose, and the office background completely unchanged.
```
Note: explicit "keep … unchanged" clauses are what preserve identity/composition across the edit.

### How to render legible in-image text
Quote the exact string; FLUX has strong typography for a diffusion model. Keep it short.
```text
A modern coffee-shop chalkboard sign reading "FRESH BREW DAILY" in clean
hand-lettered caps, warm interior bokeh behind it.
```
Note: shorter strings spell more reliably; very long copy still degrades.

### How to tune guidance for realism vs. adherence
Pick the model's regime and set guidance accordingly.
```text
# FLUX.1 [dev]: guidance 2.5–3.5, steps 20–30
# FLUX.1 [schnell]: steps 1–4, guidance ~0 (distilled — do NOT raise it)
```
Note: if photoreal output looks plasticky/over-contrasted, lower guidance toward 2; if it ignores details, raise toward 4–5.

### How to steer style without a weighting operator
State the medium/artistic frame as a clause; reinforce with 2–3 concrete descriptors, not a weight number.
```text
A fox curled asleep in autumn leaves, rendered as a soft gouache children's-book
illustration, warm limited palette, gentle paper texture.
```
Note: name the medium once and support it with texture/palette words — that's the FLUX equivalent of a style weight.

### How to compose multiple Kontext edits without drift
Chain edits one instruction at a time (edit the output of the previous step) rather than bundling several unrelated changes into one prompt.
```text
# step 1 (input = original):
Add a pair of round glasses to the man, keep everything else unchanged.
# step 2 (input = step-1 output):
Change the wall behind him to a bookshelf, keep the man and glasses unchanged.
```
Note: sequential single-change edits preserve identity far better than "add glasses and change the wall and…" in one shot.

### How to place readable text with a layout hint
Quote the string and describe its position/treatment in words; FLUX places it fairly reliably.
```text
A minimalist event poster, deep navy background, centered title "NIGHT MARKET"
in large clean sans-serif, small subtitle "Every Friday · 6pm" below it.
```
Note: keep to one or two short strings; long paragraphs of body copy still degrade.

## Do's and Don'ts

### ✅ Do
- Write **natural-language, single-scene** descriptions.
- For **Kontext**, lead with the **edit verb** and pin what to **keep unchanged**.
- Keep **guidance in the model's band** (dev 1.5–5; schnell ~0).
- **Quote in-image text** and keep phrases short.
- Match the model to the job: `schnell` for speed, `dev` for quality-local, `pro`/Kontext for best fidelity/editing.

### ❌ Don't
- Don't use SD **`(word:1.3)` weighting or `[word]` de-emphasis** — FLUX has no native prompt-weight grammar; write emphasis in words.
- Don't apply **dev CFG/steps to schnell** — the distilled model wants ~1–4 steps and ~0 guidance.
- Don't lean on a **negative prompt** — the guidance-distilled variants don't take true CFG negatives (see below).
- Don't paste **Danbooru tag walls** — that's an SD habit; FLUX reads prose.
- Don't exceed **~512 tokens** — plan prompt length to fit.

## Negative Prompts / Exclusions

FLUX's mainstream variants (`dev`, `schnell`) are **guidance-distilled and do not support a true CFG negative prompt** in the SD sense — there is no reliable "negativePrompt" lever. (Some runtimes offer an experimental "true CFG" mode that re-enables negatives at a speed cost; treat it as advanced/optional and web-verify before relying on it.)

Practical exclusion strategy: **describe the desired positive state** ("a clean cloudless sky", "an empty uncluttered table") rather than listing forbidden items. For Kontext, phrase exclusions as **preservation clauses** ("do not change the background").

## Variant selection (dev vs schnell vs pro vs Kontext)

| Variant | Access | Steps / guidance | Best for |
|---------|--------|------------------|----------|
| **[schnell]** | open (Apache-2.0) | 1–4 steps, guidance ~0 | fastest local drafts, batch exploration |
| **[dev]** | open (non-commercial license) | ~20–30 steps, guidance 1.5–5 | high-quality self-hosted generation + LoRA |
| **[pro] / 1.1 [pro]** | API only | managed | top-fidelity generation without local GPU |
| **Kontext [dev/pro/max]** | open dev + API | managed | instruction-based image **editing** & consistency |

The prep agent must match prompt idiom to the variant: schnell wants a crisp short scene (few steps can't recover from an overlong prompt); dev/pro can take a richer paragraph; Kontext wants an **imperative edit instruction + preservation clause**, not a fresh scene description.

## Styling & Control

- **Guidance scale**: primary quality lever (dev 1.5–5). schnell ≈ 0.
- **Steps**: dev ~20–30; pro API-managed; schnell 1–4.
- **Seed**: deterministic in local runtimes (Diffusers/ComfyUI) — fix to iterate.
- **LoRA**: rich open-dev LoRA ecosystem, applied at loader level; trigger words go in the prose prompt.
- **Reference conditioning**: Kontext takes an input image + instruction; other image-prompt/ControlNet-style adapters exist in the community stack.
- **Samplers**: exposed by the runtime (ComfyUI/Diffusers scheduler choice) rather than a FLUX-native flag.

## Aspect / Resolution / Duration Constraints

- **Resolution**: ~1MP class (e.g. 1024×1024) native; supports common ratios (1:1, 16:9, 9:16, 4:3, 3:4, 3:2, 2:3) via the width/height the runtime requests. Kontext preserves input dimensions on edits.
- **Prompt cap**: ~**512 tokens** (Kontext). Plan accordingly.
- **Duration**: N/A — still images (BFL video is a separate product line, out of scope here).

## Common Pitfalls & Troubleshooting

- **schnell looks noisy / washed**: you used dev-style steps/CFG. Drop to 1–4 steps, guidance ~0.
- **Plasticky over-contrast**: guidance too high — lower toward 2–2.5.
- **Ignores fine details**: guidance too low — raise toward 4–5 (dev).
- **Kontext changes too much**: add explicit "keep X unchanged" clauses and name the single thing to edit.
- **Negative prompt "does nothing"**: expected — distilled variants lack true CFG negatives; convert to positive phrasing.
- **Tag-style prompt underperforms**: FLUX wants prose — an SD-tuned prep step will hurt it.
- **LoRA not triggering**: trigger word missing from the prompt, or loaded at the wrong scope (loader node not wired).
- **LLM-prep trap**: strip any `(word:1.3)` / `--flags` a generic prep step injects — FLUX treats them as noise.

## Integration Notes (media-tool specific)

**NOT YET WIRED.** No `src/providers/flux.rs`, no `service:` id, no entry in `get_provider`, `api_key_env`, `constraints`, or `default_model`. media-tool cannot currently target FLUX.

A future integration would need:
- A `MediaProvider` impl targeting either the **BFL API** (pro/Kontext) or a local/hosted **dev/schnell** endpoint (Diffusers server / ComfyUI graph / Replicate-style host).
- `provider_options` keys the prep agent could emit: `guidance_scale`, `steps`, `seed`, `loras`, and for Kontext an `edit`/`input_image` + `preserve` intent. Choose exact key names at implementation time — **none exist yet, do not assume them**.
- A `constraints()` entry reflecting the **~512-token** prompt budget.
- A `default_model` (e.g. a `flux-1-dev` / `flux-1.1-pro` / `flux-kontext-*` id — confirm the exact API id at wiring time).
- An env var for the API key (BFL API) — name TBD (**not defined in `api_key_env` today**).
- Note: FLUX's editing story overlaps media-tool's existing Gemini attachment path (`generateContent` on `gemini-2.5-flash-image`); a FLUX provider would give a second, instruction-edit-native option.

## See Also
- Implemented image provider: [`imagen.md`](./imagen.md) (also natural-language; closest analog)
- Sibling forward-looking: [`stable-diffusion.md`](./stable-diffusion.md) (contrast: weighted tags + true negatives), [`midjourney.md`](./midjourney.md)
- Use-case guidance: [`../use-case/media-processing.md`](../use-case/media-processing.md), [`../use-case/creative-animation.md`](../use-case/creative-animation.md)
