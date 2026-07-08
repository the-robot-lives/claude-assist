# Udio — texture-first music generation (NOT YET WIRED)

Udio is a paid-SaaS music-generation model, the closest peer to Suno. Its distinguishing trait for prompt prep: Udio reads **texture, vibe, and production descriptors** more heavily than section structure. Where Suno leans on `[Verse]/[Chorus]` skeletons, Udio rewards rich genre + instrument + mix language and treats structure tags as secondary. This file is **forward-looking** — there is no Udio provider in media-tool today.

**Current model**: Udio v2 family (web-verified current major as of 2026-07; Udio iterates its model behind the product rather than exposing hard version ids). **Access**: paid SaaS.
**Wired in media-tool as**: **NOT YET WIRED (forward-looking).** No `src/providers/udio.rs` exists; `service: udio` is not routable. Music generation today goes through `service: suno`.

> Version note (web-verified 2026-07): Udio does not publish a stable API version string the way Suno exposes `V5_5`; guidance here reflects current Udio product behavior. Structure tags (`[Verse]`, `[Chorus]`) work in both platforms, but Udio weights **mix/production tags** more. Sources: [Ultimate Udio Prompt Guide 2026 (OpenMusicPrompt)](https://openmusicprompt.com/blog/udio-ai-prompt-guide), [Udio review 2026 (MusicSeed)](https://www.musicseed.ai/blog/udio-ai-music-generator-review), [Udio official](https://www.udio.com/).

## How This Model Reads Prompts

Udio reads a **single descriptive style prompt** (with optional separate lyrics), and weights **genre modifiers + production/texture descriptors** most. Think "describe the recording," not "diagram the song."

- **Ideal length**: a tight tag-style brief — genre, vocal style, mood, key instruments, production quality. Quality/mix tags at the *end* carry real weight.
- **What it weights most**: genre + texture/production language. Structure tags are understood but secondary.
- **Ordering**: `Genre → Vocal style → Mood → Key instruments → Production/mix quality`.

The community "3-part" mental model: **Top (genre)** → **Middle (vibe & instruments)** → **Bottom (production tags)**.

## Prompt Grammar / Syntax

Free-text descriptors, comma-separated, plus optional bracketed structure tags in a lyrics field. No weighting operators or `--flags`.

**Style brief:**
```text
Indie pop, breathy female vocals, nostalgic and dreamy, acoustic guitar and soft synthesizer, warm analog production, clean mix
```

**Production / "quality" tail (matters on Udio):**
```text
..., clean production, balanced mix, tight low-end, warm analog sound
```

**Structure tags (supported, secondary):**
```text
[Intro] [Verse] [Chorus] [Bridge] [Outro]
```

## How-To (worked recipes)

### How to nail a genre + vibe
Problem: generic-sounding output.
```text
Smoky late-night jazz, brushed drums, upright bass, muted trumpet, film-noir atmosphere, slow tempo, warm room reverb, clean mix
```
Note: stack a genre anchor + 3–4 concrete texture/instrument descriptors. Udio "paints" from these more than from structure.

### How to add production polish (the Udio lever)
Problem: mix feels thin or amateur.
```text
..., warm analog sound, tight low-end, balanced mix, vinyl warmth, professional master
```
Note: append 2–4 production/quality tags at the **end**. On Udio these measurably lift perceived quality — this is the biggest differentiator from Suno.

### How to write a vocal track
Problem: you want sung lyrics.
```text
STYLE:  Dream pop, airy female vocals, reverb-soaked, mid-tempo, shoegaze guitars, lush production, clean mix
LYRICS:
[Verse] City lights bleed through the window pane
[Chorus] And I'm falling slow, falling slow again
```
Note: provide lyrics separately; keep the style brief texture-led.

### How to produce an instrumental underscore
Problem: no singing, background bed only.
```text
Cinematic ambient, evolving pads, sub bass, sparse piano motif, tension-building, no vocals, wide stereo, clean mix
```
Note: state `no vocals` explicitly and lean entirely on instrument + production descriptors.

## Do's and Don'ts

### ✅ Do
- **Front-load genre, then pile on texture/instrument descriptors.**
- **End with production/quality tags** (`clean mix`, `tight low-end`) — Udio rewards them.
- **Keep lyrics in a separate field** from the style brief.
- **Describe the *recording's* character** (analog warmth, room reverb), not just the notes.

### ❌ Don't
- **Don't over-rely on `[Verse]/[Chorus]` structure** — Udio weights vibe/texture more; a structure-only prompt underperforms.
- **Don't write prose paragraphs** — comma-separated descriptor stacks read better.
- **Don't omit production tags** — a brief without them sounds flatter than the same brief with them.

## Negative Prompts / Exclusions

Udio's exclusion behavior is expressed mostly through **positive framing** ("clean, no distortion", "no vocals") rather than a first-party negative-prompt API surface exposed to us. Since there is no media-tool provider, no negative-prompt field is defined; a future integration would need to confirm whether Udio exposes an explicit exclusion parameter or expects in-prompt negation.

## Styling & Control

Udio's product exposes controls like clip length, lyrics vs instrumental, and prompt-strength/variance sliders. **Exact API parameter names are not confirmed here** — do not assume they mirror Suno's `styleWeight`/`weirdnessConstraint`. A future provider must map these from Udio's actual API.

## Aspect / Resolution / Duration Constraints

- **No aspect ratio** (audio).
- **Duration**: Udio generates in clips/extensions rather than one long render; multi-section songs are built by extending. A future provider would need to handle clip-extension or a length parameter — treat any single-call max as **unconfirmed**.

## Common Pitfalls & Troubleshooting

- **Flat/thin output** → missing production tags at the end.
- **Wrong feel** → too few texture descriptors; add concrete instruments + room/mix character.
- **Structure ignored** → expected on Udio; it prioritizes vibe. If precise arrangement matters, Suno is the better current target.
- **No provider** → any request routed to `udio` will not run in media-tool today.

## Integration Notes (media-tool specific)

**NOT YET WIRED.** There is no `src/providers/udio.rs`, no `service: udio` branch in `get_provider`, no `api_key_env` entry, and no `constraints()` row. To integrate, a future implementation would need to:
1. Add `udio` to `providers/mod.rs` (`get_provider`, `api_key_env`, `is_stub_provider`, `default_model`, `constraints`) and a candidate entry under `AssetType::Audio → AudioKind::Music`.
2. Add `src/providers/udio.rs` implementing `MediaProvider` (Udio's API is job-based/async like Suno — submit + poll + download).
3. Decide the API key env var (e.g. `UDIO_API_KEY`) and confirm whether generation is first-party API or a third-party wrapper (as Suno uses `api.sunoapi.org`).
4. Map real option keys (lyrics, instrumental flag, clip length, prompt strength) — **do not copy Suno's option names blind**; verify against Udio's schema.
Until then, prep should route music to `suno` and treat this file as design guidance only.

## See Also
- `suno.md` — the implemented music sibling; prefer it today. Structure-tag-led vs Udio's texture-led.
- `elevenlabs.md`, `openai-tts.md`, `qwen-tts.md` — voice/TTS siblings.
- `../use-case/creative-animation.md` — where generated music is consumed (if present).
