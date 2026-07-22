# Stable Diffusion — weighted-tag image generation (A1111 / ComfyUI / Forge)

Stable Diffusion is the open-weights diffusion family from Stability AI, run locally or on rented GPUs through UIs like **AUTOMATIC1111 (A1111)**, **ComfyUI**, **Forge**, and **Fooocus**. Unlike Imagen/FLUX, SD is driven by **weighted keyword prompts**, explicit **negative prompts**, and a deep stack of samplers/steps/CFG/LoRA controls. It rewards prompt-engineering precision and is the ecosystem where token weighting, LoRAs, and ControlNet actually matter.

**Current model**: SDXL 1.0 (1024² baseline) and **Stable Diffusion 3.5** (Large / Large-Turbo / Medium, released late 2024). SD 1.5 remains widely used for its LoRA library. **Access**: open weights (self-host) or hosted APIs.
**Wired in media-tool as**: **NOT YET WIRED (forward-looking)** — there is no `src/providers/stable_diffusion.rs`. This file prepares prompt guidance for a future integration.

> Version note (web-verified 2026-07): SDXL 1.0 is the dominant 1024²-native base; **SD 3.5 Large** is the current flagship open release with improved prompt adherence and typography. Weighting/LoRA/BREAK syntax below is A1111/Forge-family syntax and is shared by SDXL and SD 1.5. Sources: [Prompt syntax FAQ (Generative Labs)](https://www.generativelabs.com/insights/prompt-syntax-for-stable-diffusion-faq), [SDXL guide (sandner.art)](https://sandner.art/ultimate-guide-to-sdxl-mastering-photorealism-in-generative-art-for-begginers-and-advanced/), [Diffusers weighted prompts](https://huggingface.co/docs/diffusers/en/using-diffusers/weighted_prompts).

## How This Model Reads Prompts

SD reads a **comma-separated list of concepts/tags**, not prose sentences (though SD3.5 tolerates natural language better than 1.5/SDXL). Tokens near the **front carry more weight**; the CLIP text encoder truncates at **75 tokens per chunk** (use `BREAK` to start a fresh chunk).

- **Ideal length**: 15–40 tags in the positive prompt; a substantial negative prompt.
- **What it weights most**: leading tokens + explicitly weighted terms. Order roughly `subject, subject detail, style/medium, artist/era, lighting, quality boosters`.
- **Quality boosters** are conventional: `masterpiece, best quality, highly detailed, 8k, sharp focus` (SD 1.5/SDXL culture; less needed on SD3.5).
- **Two-encoder note (SDXL/SD3.5)**: multiple text encoders — keep the prompt coherent; contradictory tags fight each other.

## Prompt Grammar / Syntax

This is the real A1111/Forge/ComfyUI-compatible operator surface:

- **Emphasis weight**: `(word:1.3)` = 1.3× attention; `(word:0.7)` = de-emphasize. Explicit numeric form is the clearest.
- **Parenthesis shorthand**: `(word)` ≈ ×1.1, `((word))` ≈ ×1.21 (compounds); `[word]` ≈ ×0.9. Prefer explicit `:1.3` over stacking brackets.
- **LoRA**: `<lora:name:0.8>` in the positive prompt — `0.8` is the LoRA weight (typical `0.6–1.0`). Often paired with the LoRA's trigger word.
- **Textual inversion / embedding**: reference by filename token, e.g. a negative embedding like `badhandv4` dropped into the negative prompt.
- **Chunk separator**: `BREAK` (uppercase) forces a new 75-token chunk — useful to isolate a subject from a style block.
- **Prompt editing / scheduling**: `[from:to:step]`, e.g. `[a cat:a tiger:0.4]` swaps at 40% of steps. `[a|b]` alternates each step.

Minimal weighted prompt:

```text
(cyberpunk street samurai:1.2), neon rain, reflective wet asphalt, cinematic lighting,
volumetric fog, <lora:neon_noir:0.7>, highly detailed, sharp focus
```
Negative:
```text
lowres, blurry, extra fingers, bad hands, deformed, watermark, text, jpeg artifacts
```

## How-To (worked recipes)

### How to emphasize one element without collapsing the rest
Use a single explicit weight in the `1.1–1.4` band. Going past ~1.5 "burns" the token (oversaturation, artifacts).
```text
portrait of a knight, (ornate silver filigree armor:1.35), castle courtyard,
overcast light, detailed, 85mm
```
Note: if the emphasized token dominates unnaturally, lower it to `1.2` before adding more weights elsewhere.

### How to apply a LoRA at the right strength
Add the LoRA tag plus its trigger word; sweep the weight.
```text
1girl, silver hair, ornate kimono, garden, <lora:ghibli_style:0.75>, ghibli style,
soft painterly shading, warm light
```
Note: start at `0.7–0.8`; drop toward `0.5` if the LoRA overwhelms anatomy or color.

### How to build an effective negative prompt
List concrete failure modes and unwanted content; don't over-negate (huge negatives can flatten the image).
```text
(worst quality:1.4), (low quality:1.4), blurry, extra limbs, extra fingers, fused fingers,
mutated hands, disfigured, watermark, signature, text, out of frame
```
Note: reuse a curated base negative; add case-specific exclusions rather than pasting 200 tokens.

### How to hit a resolution / aspect sweet-spot
Match the base model's native training resolution, then hi-res upscale.
- **SDXL / SD3.5**: generate at ~**1024×1024** (or 896×1152, 832×1216 for portrait; 1216×832, 1152×896 for landscape).
- **SD 1.5**: generate at ~**512×512 / 512×768**, then hi-res fix to 2×.
```text
# A1111: enable "Hires. fix", upscaler R-ESRGAN 4x+, denoise 0.3–0.45, 2x
```
Note: generating far above native res without hi-res fix causes duplicated subjects ("two heads").

### How to choose sampler + steps + CFG
Sane defaults: **DPM++ 2M Karras**, **25–35 steps**, **CFG 6–8** (SDXL). `Euler a` for softer/creative; Turbo/Lightning models want very low steps + low CFG.
```text
# Sampler: DPM++ 2M Karras | Steps: 30 | CFG: 7 | Seed: 12345 (fixed for iteration)
```
Note: SD3.5-Large-Turbo and SDXL-Lightning run at ~4–8 steps, CFG ~1–2 — normal CFG will overcook them.

### How to constrain composition with ControlNet
Feed a control image (pose skeleton, depth map, canny edges, lineart) alongside the prompt; set control weight and the step window it's active.
```text
# ControlNet: openpose | weight 0.8 | start 0.0 end 0.7
prompt: knight in plate armor, dynamic action pose, castle courtyard, cinematic
```
Note: lower control weight (~0.5) or end the guidance early (~0.6) so the model still has freedom to render detail; weight 1.0 for the full window can look stiff/traced.

### How to isolate subject from style with BREAK
Split the prompt into a subject chunk and a style chunk so the 75-token encoder doesn't bleed style words into the subject.
```text
a majestic snow leopard on a rocky ledge, alert, detailed fur
BREAK
watercolor painting, soft washes, cool blue palette, paper texture
```
Note: `BREAK` (uppercase) starts a fresh CLIP chunk — useful when a long style block was contaminating the subject.

## Do's and Don'ts

### ✅ Do
- Use **comma-separated tags**, most-important first.
- Weight sparingly with **explicit `(term:1.2–1.4)`**.
- Maintain a **reusable curated negative prompt**.
- Match **native resolution** and use **hi-res fix** to upscale.
- Fix the **seed** while iterating so you can judge one variable at a time.

### ❌ Don't
- Don't push weights to `1.6+` — tokens burn (saturation, deep-fried look).
- Don't write long prose paragraphs for SD 1.5/SDXL — they read tags better (SD3.5 is more forgiving).
- Don't dump a 200-token negative "quality" wall — it can wash out the subject.
- Don't generate at 2048² on a 1.5 base without hi-res fix — expect duplicated anatomy.
- Don't mix a Turbo/Lightning checkpoint with CFG 7 and 30 steps — use its low-step, low-CFG regime.

## Negative Prompts / Exclusions

Negative prompts are **first-class and powerful** in SD (this is the ecosystem where they matter most). Put anatomical failure modes, unwanted styles, and content to suppress here. It also accepts weights: `(text:1.3)` to strongly forbid embedded text, and negative embeddings (`badhandv4`, `easynegative`) as filename tokens. Keep it curated — bigger is not better.

## Styling & Control

- **Samplers**: `DPM++ 2M Karras` (reliable default), `DPM++ 3M SDE Karras` (detail), `Euler a` (creative/soft), `UniPC` (fast few-step), `DDIM` (legacy).
- **Steps**: 20–35 typical; 15 for exploration; 4–8 for Turbo/Lightning.
- **CFG scale**: 6–8 SDXL; 7–11 SD1.5; 1–2 for Turbo/Lightning. Higher = more literal but can oversaturate.
- **Seed**: fully deterministic given fixed model + params — fix it to iterate, randomize to explore.
- **ControlNet**: pose/depth/canny/lineart conditioning from a reference image (weight + start/end percent).
- **Reference / IP-Adapter**: image-prompt conditioning for style or identity transfer.
- **Refiner (SDXL)**: optional second pass (base → refiner) for final detail; SD3.5 does not use the SDXL refiner scheme.

## SD 1.5 vs SDXL vs SD 3.5 (pick the right base)

| Base | Native res | Prompt style | Notes |
|------|-----------|--------------|-------|
| **SD 1.5** | 512² | Heavy weighted tags; needs quality boosters | Largest LoRA/embedding library; weakest text & anatomy |
| **SDXL 1.0** | 1024² | Weighted tags; two text encoders | Best community LoRA support at 1024²; optional refiner pass |
| **SD 3.5 Large** | 1024²+ | Tags OR natural language (more prose-tolerant) | Best prompt adherence + typography of the three; heavier VRAM |

A LoRA/embedding is base-specific: an SD 1.5 LoRA will not load on SDXL/SD3.5 and vice-versa. When the prep agent picks a base, it must emit prompts in that base's idiom (more boosters + tags for 1.5; leaner tags or light prose for SD3.5).

## Aspect / Resolution / Duration Constraints

- **Native**: SDXL/SD3.5 = 1024²-class; SD1.5 = 512²-class. Stay near native, then upscale.
- **Common ratios** (SDXL bucketed): 1024×1024, 1152×896, 896×1152, 1216×832, 832×1216, 1344×768, 768×1344.
- **Resolution ceiling**: bounded by VRAM; SD3.5 Large is heavier than SDXL.
- **Duration**: N/A (stills). Video is a separate lane (SVD / AnimateDiff) — out of scope here.

## Common Pitfalls & Troubleshooting

- **Duplicated subjects / "two heads"**: generating above native res without hi-res fix. Drop to native, upscale after.
- **Deep-fried oversaturation**: CFG too high or weights `>1.5`. Lower both.
- **Muddy / washed out**: negative prompt too large, or CFG too low.
- **Bad hands/anatomy**: use anatomy negatives + a hands LoRA/embedding; SD3.5/SDXL are better than 1.5.
- **LoRA does nothing**: missing trigger word, wrong base model (SD1.5 LoRA on SDXL won't load), or weight too low.
- **Turbo model looks noisy**: you used normal steps/CFG — switch to the low-step, low-CFG regime.
- **LLM-prep trap**: an Imagen/FLUX-tuned prep step will emit prose — for SD, convert to weighted tags and generate a matching negative prompt.

## Integration Notes (media-tool specific)

**NOT YET WIRED.** No `src/providers/stable_diffusion.rs`, no `service:` id, no entry in `get_provider`, `api_key_env`, `constraints`, or `default_model`. media-tool cannot currently target Stable Diffusion.

A future integration would need:
- A new `MediaProvider` impl (local A1111/Forge `/sdapi/v1/txt2img`, ComfyUI graph API, or a hosted SD endpoint).
- **Forwarding `negative_prompt`** (already on `GenerationOptions`) — SD's most important knob, currently unused by the only image provider.
- New `provider_options` keys the prep agent could emit: `sampler`, `steps`, `cfg_scale`, `seed`, `loras`, `clip_skip`, `hires_fix`/`upscaler`, `refiner`.
- A `constraints()` entry (CLIP 75-token chunking / `BREAK` awareness rather than a raw char cap) and `default_model` (e.g. an SDXL or SD3.5 checkpoint id).
- An env var for the hosted case (e.g. `SD_API_URL` / provider key) — pick a name at implementation time; **not defined yet, do not assume one**.

## See Also
- Implemented image provider: [`imagen.md`](./imagen.md) (contrast: prose vs. weighted tags)
- Sibling forward-looking: [`flux.md`](./flux.md), [`midjourney.md`](./midjourney.md)
- Use-case guidance: [`../use-case/media-processing.md`](../use-case/media-processing.md), [`../use-case/creative-animation.md`](../use-case/creative-animation.md)
