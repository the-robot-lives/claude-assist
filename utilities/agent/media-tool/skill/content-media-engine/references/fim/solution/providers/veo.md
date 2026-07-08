# Google Veo — cinematic text/image-to-video with native audio

Google DeepMind's flagship video generator. Produces short, film-grade clips from a text prompt (text-to-video) or from a still frame + prompt (image-to-video), with **native synchronized audio** — dialogue, ambient sound, and effects generated together with the picture. Best at photoreal cinematic shots, physically plausible motion, and prompt adherence to explicit camera direction. Access is paid API only (Gemini API / Vertex AI); no open weights.

**Current model**: Veo 3.1 is the current public generation (Fast / standard / Lite tiers); Veo 3 is the prior generation still widely served. **Access**: paid SaaS API (Google Gemini API + Vertex AI).
**Wired in media-tool as**: `service: veo` (see `src/providers/veo.rs`). The provider defaults to `veo-3.0-generate-001` and the candidate table also selects `veo-3.0-fast-generate-001` — i.e. **media-tool currently pins the Veo 3.0 family**, not 3.1. Prompt guidance below is Veo-3-generation and forward-compatible with 3.1.

> Version note (web-verified 2026-07): "Veo 3.1" with scene-extension and improved audio is the headline current model, but the wired model IDs in this repo are `veo-3.0-generate-001` / `veo-3.0-fast-generate-001`. Write prompts to the Veo 3 contract; they carry forward to 3.1. If someone bumps the model ID, the prompt grammar does not change.

## How This Model Reads Prompts

Veo reads **natural-language, cinematographer-style descriptions** — full sentences, not comma-salad tag lists. It rewards a prompt that reads like a shot brief handed to a film crew. The strongest lever is **explicit, ordered scene description**: establish the shot, then the subject, then what moves, then the camera, then the mood/lighting.

Recommended ordering (Google's five-part formula), front-load the most important:

1. **Cinematography / shot** — shot size + camera framing ("Low-angle wide shot", "Slow dolly-in medium close-up").
2. **Subject** — who/what, with concrete visual detail.
3. **Action** — what the subject does, as a single clear beat (one 8-second clip = one action, not five).
4. **Context** — environment, time of day, background elements.
5. **Style & ambiance** — aesthetic, lighting, color palette, mood; audio cues.

Ideal prompt length: **roughly 40–120 words**. Veo has a hard input ceiling (media-tool caps it at **1000 characters** — see Integration Notes), so be dense and cinematic, not padded. One clip should depict **one continuous action beat** in one location; asking for a multi-scene montage in 8 seconds produces cuts the model handles poorly.

## Prompt Grammar / Syntax

Veo has **no weighting/flag mini-language** (no `(word:1.3)`, no `--ar`, no LoRA). All control is either (a) plain-English description inside the prompt, or (b) structured API parameters (aspect ratio, duration, resolution, personGeneration) passed as fields, not prompt tokens.

Audio is prompted **in natural language** inside the same prompt. Three idioms Veo recognizes well:

```
Dialogue:  The barista says: "We're out of oat milk again."
Ambient:   Audio: rain on a tin roof, distant traffic, a low electrical hum.
SFX:       A ceramic cup clinks against the saucer as she sets it down.
```

Put dialogue in quotation marks attributed to a speaker. Keep spoken lines short — an 8-second clip fits roughly one or two sentences of speech. To **suppress** unwanted captions/subtitles, say so in words ("no subtitles, no on-screen text").

Minimal text-to-video example:

```
Slow dolly-in on a lone lighthouse keeper at dusk, weathered face lit by
a swinging lantern. He turns toward the churning sea as waves crash below.
Overcast, desaturated cinematic color grade. Audio: howling wind, crashing
surf, the creak of the lantern chain. No subtitles.
```

Minimal image-to-video example (still frame supplied as an attachment):

```
The subject in the frame slowly raises her head and smiles as morning light
warms the room. Gentle handheld camera drift. Ambient: soft birdsong, a
distant kettle. Keep the character's face and clothing consistent.
```

## How-To (worked recipes)

### How to order a shot for maximum control
Lead with camera + shot size, then subject, then the single action, then lighting/audio:
```
Aerial tracking shot descending toward a cyclist on an empty coastal highway
at golden hour. She stands on the pedals and accelerates into a curve. Warm
backlight, long shadows, anamorphic lens flare. Audio: wind rush, tire hum,
faint gulls.
```
Note: naming the shot type first ("Aerial tracking shot") is the single biggest quality lever in Veo.

### How to get clean synchronized dialogue
Attribute the line to a visible speaker and keep it to one short sentence for an 8s clip:
```
Medium close-up of a detective in a rain-streaked car. He lifts a photograph
and mutters, "So it was you all along." Low key lighting, blue-green grade.
Audio: rain on glass, distant thunder. No subtitles, no captions.
```
Note: over-long dialogue gets truncated or rushed; one clip ≈ one line. Always add "no subtitles" unless you want burned-in text.

### How to drive the camera explicitly
Veo understands standard film-camera vocabulary — use it verbatim:
```
Dolly-in from wide to medium, then a slow tilt up to reveal the skyline.
Handheld micro-shake for a documentary feel.
```
Note: pick moves that fit one continuous beat (dolly, pan, tilt, orbit, crane, push-in, pull-out). Do not stack a dolly + whip-pan + cut into 8 seconds.

### How to keep an image-to-video subject consistent
When supplying a start frame, describe **only the motion** and explicitly instruct preservation:
```
The character in the provided frame turns to look over her shoulder, hair
shifting in the breeze. Keep her face, hairstyle, and jacket exactly as in
the source image. Subtle slow-motion. Ambient wind.
```
Note: in image-to-video the still already carries the look — do not re-describe appearance in detail or you invite drift; spend words on motion + a "keep consistent" clause.

### How to hit a target aspect ratio, length, and resolution
These are **API parameters, not prompt text** — set them via provider options / GenerationOptions:
```
aspect ratio: 16:9   duration: 8   resolution: 1080p
```
Note: Veo 3 durations are constrained to **4, 6, or 8 seconds**; do not write "a 30-second clip" in the prompt — it is ignored and the parameter wins.

### How to render legible on-screen text or a logo
Veo can place short text if you quote it exactly and keep it brief:
```
Close-up of a hand-painted café sign that reads "OPEN" in cream cursive
on chalkboard, warm shop light. No other text on screen.
```
Note: request one short string in quotes; long or multi-word text warps. If you don't want text, say "no on-screen text" — Veo tends to hallucinate signage otherwise.

### How to pace motion within the 8-second beat
Use tempo words to control speed instead of asking for cuts:
```
Slow-motion: a water droplet falls and crowns on a still pond, ripples
spreading languidly. Time seems to stretch.
```
Note: "slow-motion", "real-time", "time-lapse", "languid", "frantic" all read as pacing; they shape one continuous beat rather than splitting the clip.

## Worked prompt template (prep agent: fill and trim to ≤1000 chars)

```
[SHOT TYPE + CAMERA MOVE] of [SUBJECT with 1–2 concrete visual details],
[SINGLE ACTION BEAT]. [ENVIRONMENT / time of day]. [LIGHTING + color grade],
[lens/film look]. Audio: [ambient bed], [1 specific SFX][; dialogue: "<one
short line>"]. No subtitles, no on-screen text.
```

Filled:
```
Low-angle tracking shot of a courier cycling through a rain-soaked night
market, tail-light streaking. She weaves between stalls and glances back.
Wet neon reflections, teal-and-magenta grade, shallow depth of field. Audio:
rain, sizzling woks, a distant scooter horn. No subtitles.
```

## Prep-agent checklist (before emitting a Veo prompt)

- [ ] Prose sentences, not a comma tag-list.
- [ ] Shot type + camera move named in the **first clause**.
- [ ] Exactly **one** action beat in **one** location.
- [ ] Lighting + color grade specified.
- [ ] Audio line present (ambient + SFX; dialogue ≤1 short line, in quotes, attributed).
- [ ] "No subtitles / no on-screen text" appended (unless text is wanted).
- [ ] Exclusions folded into prose (no negative-prompt field for Veo).
- [ ] Under **1000 characters** total.
- [ ] Duration/aspect/resolution left to parameters, not written in prose.

## Do's and Don'ts

### ✅ Do
- Write full cinematic sentences; name the **shot type and camera move** explicitly.
- Keep one clip to **one action beat in one location**.
- Prompt audio deliberately (dialogue in quotes + ambient + SFX line).
- In image-to-video, describe **motion only** and add "keep consistent."
- Add "no subtitles / no on-screen text" unless you actually want captions.
- Specify lighting and color grade — Veo renders mood strongly from these.

### ❌ Don't
- Don't use tag-list / comma-salad prompts (`robot, neon, 4k, cinematic, trending`) — Veo is a natural-language model and this flattens output.
- Don't cram multiple scenes or shot changes into one 8-second clip — you get muddy cuts.
- Don't write parameter flags into the prompt (`--ar 16:9`, `(word:1.3)`) — Veo ignores them and they waste your 1000-char budget.
- Don't write long paragraphs of dialogue — one clip fits ~one line.
- Don't over-describe appearance in image-to-video — it fights the source frame.

## Negative Prompts / Exclusions

Veo does **not** expose a dedicated weighted negative-prompt field via the media-tool wiring. The `GenerationOptions.negative_prompt` slot exists in the pipeline but Veo's request body (see `veo.rs`) does not forward a separate negative parameter — so **express exclusions in natural language inside the main prompt**: "no subtitles, no lens dirt, no extra people in the background, no text overlays." Keep exclusions short and concrete; a long list of negations eats the character budget and dilutes the positive description. Prefer positive phrasing where possible ("an empty street" beats "no people").

## Styling & Control

- **No samplers / CFG / seed knobs** are surfaced — Veo is not a diffusion-parameter model from the caller's side. Style is controlled entirely through descriptive language.
- **Lighting & grade**: name them ("low-key", "high-key", "golden hour backlight", "teal-and-orange grade", "desaturated documentary look") — these are among the strongest style levers.
- **Lens & film look**: "anamorphic lens flare", "shallow depth of field", "35mm film grain", "macro lens" all read reliably.
- **personGeneration**: an API parameter (`allow_all` default) that gates whether people/faces may be generated — a content-safety control, not a style control.
- **Reference frame weighting**: the first attachment becomes the image-to-video start frame; there is no numeric weight — consistency is steered by the "keep consistent" clause.

## Aspect / Resolution / Duration Constraints

- **Duration**: Veo 3 supports **4, 6, or 8 seconds** per clip (media-tool defaults to 8; `durationSeconds` parameter). Longer narratives are built by chaining/extending clips, not by one long request. (Veo 3.1 adds scene-extension chaining toward ~140s — not exposed in the current wiring.)
- **Resolution**: **720p** (media-tool default) and **1080p**; 4K exists on newer tiers with added latency/cost. Set via the `resolution` provider option.
- **Aspect ratio**: **16:9** (default) and **9:16** are the reliable pair; set via `aspectRatio`. Other ratios are less predictable.
- **Generation time**: minutes, not seconds — the provider polls a long-running operation (10s interval, up to ~10 min). Plan for async behavior.

## Common Pitfalls & Troubleshooting

- **1000-char cap** (media-tool): prompts are truncated upstream — keep it dense. If output ignores late details, the prompt was likely clipped.
- **Content filtering**: Veo refuses or blanks on real public figures, explicit content, and some brand/IP; `personGeneration` further restricts people. A silent "done but no video" often means a safety block — soften the subject.
- **Burned-in subtitles**: Veo loves to add captions when dialogue is present — always add "no subtitles."
- **Duration ignored**: writing a duration in the prompt does nothing; only the `durationSeconds` parameter (4/6/8) counts.
- **Multi-scene mush**: asking for a story in 8 seconds yields awkward internal cuts — split into multiple clips.
- **Model-ID drift**: this repo pins `veo-3.0-*`; if generations look dated vs. current marketing, that's the pinned 3.0 family, not a prompt problem.
- **LLM-prep trap**: don't let the prep step convert the cinematic sentences into a keyword list — Veo specifically wants prose.

## Integration Notes (media-tool specific)

- **Service id**: `veo` — factory in `src/providers/mod.rs` (`get_provider("veo") -> VeoProvider`).
- **API key env**: `GEMINI_API_KEY` (shared with the `gemini`/Imagen image provider; see `api_key_env`).
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/{model}:predictLongRunning` — asynchronous, polled for completion.
- **Default model**: `veo-3.0-generate-001`; candidate table (`candidates_for`) also uses `veo-3.0-fast-generate-001` for Low/Medium video quality and `veo-3.0-generate-001` for High.
- **Prompt cap**: `constraints("veo")` → `max_prompt_chars: Some(1000)`. The prep agent must fit the whole cinematic prompt (incl. audio + exclusions) inside 1000 chars.
- **Options keys read from `provider_options`** (exact strings in `veo.rs`):
  - `aspectRatio` (string; default `16:9`; also fed by `GenerationOptions.aspect_ratio`)
  - `durationSeconds` (int/str; default `8`; also fed by `GenerationOptions.duration_seconds`, which takes precedence)
  - `resolution` (string; default `720p`)
  - `personGeneration` (string; default `allow_all`)
- **Attachments**: the first attachment is sent as the image-to-video start frame (`instances.image.bytesBase64Encoded` + `mimeType`).
- **Negative prompt**: `GenerationOptions.negative_prompt` is **not** forwarded to Veo's request body — put exclusions in the prompt text.

## Example gallery (with why-it-works notes)

**Product hero (text-to-video):**
```
Slow orbiting macro shot of a matte-black wireless earbud rotating on a lit
pedestal, soft studio key light with a crisp rim highlight, seamless white
background. Faint electronic shimmer as it turns. No text on screen.
```
Why: camera-first, single subject, one continuous motion, studio lighting named, exclusion for stray text — everything Veo weights.

**Character moment (image-to-video, still supplied):**
```
The woman in the frame slowly lowers her newspaper and raises an eyebrow,
then a small knowing smile. Subtle handheld drift. Keep her face, glasses,
and coat exactly as in the source. Audio: café murmur, a spoon on porcelain.
```
Why: motion-only, explicit "keep consistent", light ambient audio, no appearance re-description to fight the frame.

**Dialogue beat:**
```
Medium close-up, shallow focus, of a weary pilot in a dim cockpit. He keys
the radio and says, "Mayday, this is flight two-two-one." Amber gauge glow,
blue night beyond the glass. Audio: engine drone, radio static. No subtitles.
```
Why: one short quoted line for an 8s clip, speaker visible, lighting + audio set, subtitles suppressed.

## See Also

- `grok-video.md` — sibling implemented video provider (xAI Grok Imagine), different prompt style + longer clips.
- `runway-gen3.md`, `sora.md` — forward-looking video providers (not yet wired).
- `../use-case/creative-animation.md` — when/why to pick video generation for a channel (if present).
- `gemini.md` — the sibling `gemini`/Imagen image provider that shares `GEMINI_API_KEY`.
