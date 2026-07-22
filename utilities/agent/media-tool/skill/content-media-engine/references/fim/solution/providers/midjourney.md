# Midjourney — comma-phrase prompts + `--` parameter flags (SaaS)

Midjourney is a paid, closed SaaS image generator (Discord bot + web app at midjourney.com). Its prompt style sits between SD tags and prose: **short comma-separated phrases** describing subject and style, followed by **`--` parameter flags** (`--ar`, `--v`, `--style`, `--sref`, `--cref`/Omni, `--no`). It is tuned for aesthetically pleasing output out-of-the-box, so it needs less "quality booster" scaffolding than Stable Diffusion.

**Current model**: **V8.1** is the default as of late July 2025 (smarter, better text, HD mode). **V7** (April 2025) remains selectable and introduced personalization + Omni Reference. **Access**: paid SaaS only (no API/self-host; there is no official generation API).
**Wired in media-tool as**: **NOT YET WIRED (forward-looking)** — no `src/providers/midjourney.rs`, and no official API to call. This file prepares prompt guidance only.

> Version note (web-verified 2026-07): V7 released April 3 2025 and became default June 17 2025; the default was later updated to **V8.1**. `--cref` (character reference) was **superseded by Omni Reference (`--oref` / "omni reference")** in V7+ — prefer Omni Reference on current versions; `--cref` guidance below applies to V6-era prompts. Sources: [Midjourney Version docs](https://docs.midjourney.com/hc/en-us/articles/32199405667853-Version), [Parameter List](https://docs.midjourney.com/hc/en-us/articles/32859204029709-Parameter-List), [Style Reference docs](https://docs.midjourney.com/hc/en-us/articles/32180011136653-Style-Reference).

## How This Model Reads Prompts

Midjourney reads a **compact comma-separated phrase list**, then applies the trailing flags. It is opinionated: a short prompt already yields a polished, stylized image, so **over-describing fights its aesthetic engine**.

- **Ideal length**: ~5–20 words of phrases for the image content; keep it punchy. Flags go **at the end**.
- **What it weights most**: the concepts named + the flags. Earlier phrases lean slightly heavier. Use **`::` prompt weights** to split/balance concepts (`hot::1 dog::2`).
- **Ordering guidance**: `subject, key descriptors, style/medium, lighting/mood, [flags]`. Put all `--flags` last.
- **Less scaffolding needed**: skip "masterpiece, best quality, 8k" walls — that's SD culture; Midjourney bakes in aesthetics. Use `--style raw` when you want *less* of its automatic beautification.

## Prompt Grammar / Syntax

Real, current parameter surface (flags always trail the text):

- **`--ar W:H`** — aspect ratio (e.g. `--ar 16:9`, `--ar 2:3`).
- **`--v <n>`** — model version (`--v 7`); V8.1 is current default so omit to get it, or pin an older version explicitly.
- **`--style raw`** — reduce Midjourney's default aesthetic pass for more literal prompt control.
- **`--sref <url|code>`** — **style reference** (image URL or numeric sref code); **`--sw <0–1000>`** sets style strength (default 100); **`--sv <n>`** picks the sref algorithm version (V7 default `--sv 6`).
- **Omni Reference (V7+)** — supply a reference image for **character/object identity**; **`--ow <n>`** ("omni weight") controls how strongly it's enforced. This **replaces `--cref`** from V6.
- **`--cref <url>` + `--cw <0–100>`** — V6-era character reference; low `--cw` = face only, high = face+hair+clothes. Use Omni Reference on V7+ instead.
- **`--no <terms>`** — negative/exclude (see below).
- **`--chaos <0–100>`** — variation/diversity across the 4-up grid; **`--stylize <0–1000>`** — strength of MJ's house aesthetic; **`--weird <0–3000>`** — offbeat aesthetics; **`--seed <n>`** — reproducibility; **`--tile`** — seamless tiles.
- **`::` weights** — separate weighted concepts: `space::2 ship::1`.

Minimal prompt:
```text
lone astronaut on a red desert dune, distant ringed planet, cinematic, backlit --ar 16:9 --style raw
```
With style + character refs (V7):
```text
detective in a rain-soaked alley, neon reflections, film-noir --ar 2:3 --sref 1234567 --sw 250 --ow 120
```

## How-To (worked recipes)

### How to hit a target aspect ratio
Append `--ar`; it's the most reliable framing lever.
```text
sweeping mountain vista at dawn, layered fog, epic scale --ar 21:9
```
Note: extreme ratios (e.g. 21:9) can duplicate elements — nudge toward 16:9 if you see repeats.

### How to lock a recurring style across images
Reuse one `--sref` (URL or code) and tune `--sw`.
```text
product hero shot of a ceramic vase, soft studio light --ar 4:5 --sref https://ref.img/style.png --sw 300
```
Note: raise `--sw` toward 500–1000 to enforce the reference style harder; lower it to blend.

### How to keep a consistent character (V7 Omni Reference)
Attach the character image as an Omni Reference and set `--ow`.
```text
young woman with a red scarf, walking through a market, candid --ar 3:4 --ow 130
```
Note: higher `--ow` locks identity (face+hair+outfit) harder; on V6 use `--cref <url> --cw 100` instead.

### How to exclude unwanted elements
Use `--no` with the things to omit — do NOT phrase them as "no X" in the text.
```text
a serene forest clearing, wildflowers, morning light --ar 16:9 --no people, path, text
```
Note: `--no path` removes paths; writing "no path" in the prompt can paradoxically add one.

### How to make output more literal vs. more stylized
Trade `--style raw` + low `--stylize` (literal) against high `--stylize` (house aesthetic).
```text
technical cutaway of a wristwatch movement, labeled parts --style raw --stylize 50 --ar 4:3
```
Note: `--style raw` + low `--stylize` respects prompt detail; crank `--stylize` up for glossy, artistic interpretation.

### How to balance two competing concepts with `::` weights
Split concepts with `::` and give the dominant one a higher number so one doesn't swallow the other.
```text
cyberpunk city::2 zen garden::1 --ar 16:9
```
Note: `::` is a hard separator with a weight; without it "cyberpunk city zen garden" blends into one muddled idea.

### How to explore variants fast in one prompt (permutations)
Use `{a, b, c}` permutation syntax to fan out a batch (Midjourney expands it into multiple jobs).
```text
a lighthouse at {dawn, dusk, midnight}, dramatic sky, cinematic --ar 3:2
```
Note: permutations multiply job cost — three brace groups of three = nine renders.

## Do's and Don'ts

### ✅ Do
- Keep the **text short** (comma phrases); let MJ's aesthetics do the lifting.
- Put **all `--flags` at the end** of the prompt.
- Use **`--no`** for exclusions and **`--sref`/Omni Reference** for consistency.
- Use **`--style raw`** when you need literal, un-beautified control.
- Reuse a **`--seed`** to iterate on the same composition.

### ❌ Don't
- Don't write **long prose paragraphs** — MJ over-stylizes and loses the point.
- Don't phrase exclusions as **"no X" in the text** — use `--no X` (in-text negation often backfires).
- Don't paste **SD quality-booster / Danbooru tag walls** — unnecessary and muddying.
- Don't use **SD `(word:1.3)` weighting** — Midjourney uses **`::` weights**, not parentheses.
- Don't assume an **API** — there's no official generation endpoint to automate against.

## Negative Prompts / Exclusions

Midjourney's negative mechanism is the **`--no` flag**: `--no text, watermark, extra fingers`. It also supports **negative `::` weights** (`plant::-0.5`) to push a concept away. Put unwanted *content* in `--no`; do not stuff anatomical "quality" negatives the way you would for SD — MJ's base aesthetics already suppress most of that. Avoid writing "without X"/"no X" as prose; the parser handles exclusion through `--no`, not natural-language negation.

## Styling & Control

- **`--stylize` (0–1000)**: strength of MJ's signature aesthetic. Low = literal, high = artistic.
- **`--chaos` (0–100)**: spread across the 4 grid images — higher = more varied concepts.
- **`--weird` (0–3000)**: unconventional aesthetics.
- **`--sref` / `--sw` / `--sv`**: style-reference image/code, its weight, and algorithm version.
- **Omni Reference / `--ow`** (V7+): character/object identity lock (replaces `--cref`/`--cw`).
- **`--seed`**: reproducibility across runs (approximate; MJ is not fully deterministic).
- **`--tile`**: seamless repeating textures.
- **No samplers/steps/CFG exposed** — the diffusion process is fully abstracted.

## Aspect / Resolution / Duration Constraints

- **Aspect ratio**: flexible via `--ar` (1:1 default; common 16:9, 9:16, 2:3, 3:2, 4:5, 21:9). Very wide/tall ratios risk element duplication.
- **Resolution**: model-managed; V8.1 **HD mode** renders ~2× dimensions / 4× pixels vs V7. Upscale/enhance actions available in-app.
- **Duration**: still images (Midjourney video is a separate feature; out of scope here).

## Common Pitfalls & Troubleshooting

- **Exclusion added the thing you excluded**: you wrote "no X" in the prompt — move it to `--no X`.
- **Output too stylized / not literal**: add `--style raw` and lower `--stylize`.
- **Duplicated subjects at wide ratios**: pull `--ar` back toward 16:9; add a single clear subject.
- **Character drifts between images**: use Omni Reference `--ow` (V7+) or `--cref --cw` (V6); reuse `--seed`.
- **Version mismatch**: features differ by model — `--sv`, Omni Reference, HD mode are V7/V8-era; don't expect them on pinned older `--v`.
- **`::` vs `()`**: parentheses aren't weights here — use `concept::2`.
- **Automation trap**: there is **no official API** — do not assume media-tool can call Midjourney programmatically; it can't today.

## Integration Notes (media-tool specific)

**NOT YET WIRED — and structurally hard to wire.** No `src/providers/midjourney.rs`, no `service:` id, and **no official Midjourney generation API**. media-tool cannot target Midjourney today, and a clean integration is blocked by the lack of a sanctioned endpoint (Discord-bot automation and third-party unofficial APIs exist but are ToS-risky and out of scope).

If/when an official API appears, an integration would need:
- A `MediaProvider` impl against that endpoint.
- `provider_options` keys mirroring the flags: `ar`, `version`, `style` (`raw`), `stylize`, `chaos`, `weird`, `sref`/`sw`/`sv`, `omni_ref`/`ow`, `no` (exclusions), `seed`, `tile`. The prep agent would emit the trailing-flag string. Key names TBD — **none exist yet**.
- A `constraints()` entry (Midjourney favors short prompts; no large char budget needed).
- A `default_model`/version pin (e.g. `v8.1`).
- An env var for the API key — name TBD (**not in `api_key_env`**).
- Meanwhile the prep agent can still *format* Midjourney-style prompts (phrases + flags) for a human to paste into the Midjourney app.

## See Also
- Implemented image provider: [`imagen.md`](./imagen.md) (the only channel media-tool can actually generate images through today)
- Sibling forward-looking: [`stable-diffusion.md`](./stable-diffusion.md), [`flux.md`](./flux.md)
- Use-case guidance: [`../use-case/media-processing.md`](../use-case/media-processing.md), [`../use-case/creative-animation.md`](../use-case/creative-animation.md)
