# xAI Grok Imagine (video) — fast social-native clips with audio

xAI's video generator, part of the Grok Imagine family. Turns a short text prompt (text-to-video) or a still image (image-to-video) into a punchy clip with **native audio**, tuned for fast iteration and social/short-form content. Best at lively, stylized, motion-forward shots and quick turnaround; less about long-form cinematic control. Access is paid API only via the xAI platform.

**Current model**: Grok Imagine Video 1.5 is the current generation (image-to-video at up to 1080p; 6–15s clips, 24fps, native audio); Grok Imagine 1.0 is the prior GA generation (10s, 720p). **Access**: paid SaaS API (api.x.ai).
**Wired in media-tool as**: `service: grok-video` (see `src/providers/grok_video.rs`). The provider defaults to model id **`grok-imagine-video`** (a stable alias, not a pinned `1.5`/`1.0` string).

> Version note (web-verified 2026-07): current is **Grok Imagine 1.5** (6–15s, 720p @24fps native audio; 1080p for image-to-video). Media-tool sends the generic `grok-imagine-video` model id, so it tracks whatever xAI maps that alias to. Prompt guidance below targets the current Grok Imagine generation.

## How This Model Reads Prompts

Grok reads **compact natural-language prompts** and favors a **formula-style, front-loaded** structure over long cinematic paragraphs. It responds best to a tight recipe:

**Subject → Action → Camera movement → Motion detail → Mood/style → (duration cue)**

Example the model handles well:
```
A tiny robot barista slides a glowing coffee cup toward the camera, steam
rises dramatically, neon café background, playful motion, cozy vibe.
```

Ideal length: **~15–60 words**. Grok rewards a clear single subject and one motion idea; it does not need (and can be hurt by) the dense multi-clause shot briefs that Veo likes. Keep it energetic and specific. One clip = one motion beat. Style cues ("documentary", "vintage film", "commercial ad", "anime") apply reliably and can be kept consistent across a series.

## Prompt Grammar / Syntax

No weighting or flag mini-language (`(word:1.3)`, `--ar`, LoRA are **not** supported). Control is plain-English description plus structured request fields (duration, aspect_ratio, resolution) passed as JSON, not prompt tokens.

Audio is described **in the prompt text**. Camera direction is plain English — Grok understands standard moves ("slow push-in", "gentle pan", "handheld", "orbit"):

```
Camera:  slow push-in, then a gentle pan left
Motion:  steam curls upward, neon sign flickers
Mood:    playful, upbeat
Audio:   espresso machine hiss, soft lo-fi beat
```

Minimal text-to-video example:
```
A neon-lit street racer drifts around a rain-slick corner, sparks flying,
low chase-cam behind the car, motion blur, cinematic night, engine roar
and tire screech.
```

Minimal image-to-video example (source still supplied as attachment):
```
The character in the image turns and grins as confetti bursts behind them,
gentle handheld camera, celebratory mood, cheering crowd audio. Keep the
face and outfit consistent.
```

## How-To (worked recipes)

### How to structure a prompt Grok likes
Use the front-loaded formula; keep one subject + one motion:
```
A golden retriever leaps to catch a frisbee in a sunny park, slow-motion,
low tracking shot, joyful mood, ambient park sounds.
```
Note: subject first, then the single action, then camera + mood — Grok's sweet spot is compact and punchy, not paragraph-length.

### How to direct the camera for a "filmic" look
Name the move explicitly — Grok visibly upgrades generic prompts when camera is specified:
```
Slow push-in on a lone astronaut at a cracked window, distant Earth beyond,
handheld micro-shake, tense ambient hum.
```
Note: "slow push-in / gentle pan / handheld feel" reliably beat an unspecified camera.

### How to lock a style across a series
Put the style cue in the same slot every time and reuse it:
```
[shot 1] A barista latte-art heart forms, macro, vintage film look, warm grade.
[shot 2] The cup slides across the counter, vintage film look, warm grade.
```
Note: repeating the exact style phrase ("vintage film look, warm grade") keeps a multi-clip sequence visually consistent.

### How to animate a supplied still (image-to-video)
Describe **motion only** and add a consistency clause; the still carries the appearance:
```
The subject in the frame slowly blinks and the wind lifts their scarf; petals
drift past. Subtle slow-motion, soft ambient breeze. Keep the character
consistent with the source image.
```
Note: image-to-video is where Grok's 1080p path lives; don't re-describe the subject's looks — spend words on the movement.

### How to hit target duration / ratio / resolution
Set them as request fields, not prompt words:
```
duration: 10   aspect_ratio: 16:9   resolution: 720p
```
Note: current clips are ~6–15s; longer sequences are built by chaining "extend from frame," not by asking for a 60s clip.

### How to make a vertical social clip
Set 9:16 and describe framing that fits a phone screen:
```
A skateboarder ollies over a puddle, low upward angle, spray flies at the
lens, energetic, street ambience, upbeat lo-fi beat.
```
Note: pair `aspect_ratio: 9:16` with a subject framed tall/centered; Grok's short punchy style suits vertical social natively.

### How to get native audio that matches the shot
Name an ambient bed plus one or two SFX and (optionally) a music genre:
```
A campfire crackles under a starry sky, sparks drifting up, slow orbit,
calm mood. Audio: fire crackle, crickets, soft acoustic guitar.
```
Note: Grok generates sound with the picture — a concrete audio line noticeably lifts perceived quality.

## Worked prompt template (prep agent: keep compact, ≤1000 chars but aim far shorter)

```
[SUBJECT] [SINGLE ACTION], [CAMERA MOVE], [MOTION DETAIL], [MOOD/STYLE cue].
Audio: [ambient], [SFX][, music genre].
```

Filled:
```
A neon jellyfish drifts through a dark aquarium tank, slow push-in, tentacles
rippling, dreamy and calm, cinematic. Audio: soft water hum, ambient synth pad.
```

## Prep-agent checklist (before emitting a Grok prompt)

- [ ] Compact — one subject, one motion beat (not a Veo-style paragraph).
- [ ] Formula order: Subject → Action → Camera → Motion → Mood.
- [ ] Camera move named ("slow push-in", "handheld").
- [ ] Audio line present (ambient + SFX; optional music genre).
- [ ] Style cue included and reused verbatim if part of a series.
- [ ] For image-to-video: motion-only + "keep consistent"; supply the still for the 1080p path.
- [ ] Exclusions phrased positively, inside the prompt.
- [ ] Duration/ratio/resolution left to request fields.

## Do's and Don'ts

### ✅ Do
- Use the compact **Subject → Action → Camera → Motion → Mood** formula.
- Keep **one subject and one motion beat** per clip.
- Name the camera move ("slow push-in", "handheld") — it measurably helps.
- Describe audio (ambient + SFX) in the prompt; Grok generates native sound.
- For image-to-video, describe **motion only** + "keep consistent."
- Reuse an exact style phrase across clips for a consistent series.

### ❌ Don't
- Don't write Veo-style dense multi-clause cinematic paragraphs — Grok prefers punchy.
- Don't cram several actions/scenes into one clip — pick one motion.
- Don't use weighting or flag syntax (`(word:1.3)`, `--ar`) — unsupported, wasted characters.
- Don't over-describe appearance in image-to-video — it fights the source frame.
- Don't rely on long spoken dialogue — short clips fit at most a line or two.

## Negative Prompts / Exclusions

The media-tool Grok request body (see `grok_video.rs`) does **not** forward a dedicated negative-prompt field, and `GenerationOptions.negative_prompt` is not sent. Express exclusions in **plain language inside the prompt**: "no text overlays, no extra people, no watermark." Keep it short and prefer positive phrasing ("an empty road" over "no cars"). A long negation list crowds out the positive description in Grok's short-prompt budget.

## Styling & Control

- **No diffusion knobs** (no sampler/CFG/steps/seed surfaced) — style is driven by descriptive language and style cues.
- **Style cues** that read reliably: "documentary", "romantic", "cozy", "vintage film", "commercial ad", "anime", "cinematic night". These are strong and reusable.
- **Camera vocabulary**: push-in, pan, tilt, orbit, tracking, handheld — all understood.
- **Audio**: native and prompt-driven; name ambient bed + specific SFX. Music genre cues ("lo-fi beat", "orchestral swell") work.
- **Reference image weighting**: the first attachment becomes the image-to-video source (sent as a `data:` URL); there is no numeric weight — consistency is steered by a "keep consistent" clause and by the still itself.

## Aspect / Resolution / Duration Constraints

- **Duration**: current Grok Imagine clips run **~6–15 seconds** (1.0 was fixed ~10s). Media-tool defaults `duration` to **10**. Longer sequences: chain "extend from frame."
- **Resolution**: **720p** is the baseline (media-tool default). **1080p** is available specifically on the **1.5 image-to-video** path. Set via the `resolution` option.
- **Frame rate**: ~24fps (native audio synced).
- **Aspect ratio**: **16:9** (default) and vertical **9:16** for social; set via `aspect_ratio`.
- **Generation time**: seconds-to-minutes; the provider polls (5s interval, up to ~15 min).

## Common Pitfalls & Troubleshooting

- **1000-char cap** (media-tool `constraints("grok-video")`): prompts truncate upstream — Grok wants short anyway, so this rarely bites, but keep exclusions terse.
- **Content filtering**: xAI blocks explicit content, real public figures, and some IP; a `failed`/`expired` poll status often means a safety or capacity rejection — soften or retry.
- **Over-long prompts flatten output**: a paragraph meant for Veo makes Grok muddy — compress to the formula.
- **Duration in prompt ignored**: only the `duration` request field counts; writing "30-second" does nothing.
- **1080p only on i2v**: expecting 1080p from a text-only prompt may silently fall back to 720p — supply a source image for the HD path.
- **LLM-prep trap**: don't let the prep step balloon a Grok prompt into a cinematic essay; keep it compact and formula-shaped.

## Integration Notes (media-tool specific)

- **Service id**: `grok-video` — factory in `src/providers/mod.rs` (`get_provider("grok-video") -> GrokVideoProvider`).
- **API key env**: `XAI_API_KEY` (see `api_key_env`; note the `zai`/`z.ai` chat providers also key off `XAI_API_KEY`).
- **Endpoint**: `POST https://api.x.ai/v1/videos/generations`, then poll `GET /v1/videos/{request_id}` for `status: done|failed|expired|pending`. `Authorization: Bearer $XAI_API_KEY`.
- **Default model**: `grok-imagine-video` (also the `default_model("grok-video")` value and the candidate-table model for all video tiers where Grok appears).
- **Prompt cap**: `constraints("grok-video")` → `max_prompt_chars: Some(1000)`.
- **Options keys read from `provider_options`** (exact strings in `grok_video.rs`):
  - `duration` (int; default `10`; also fed by `GenerationOptions.duration_seconds`, which takes precedence)
  - `aspect_ratio` (string; default `16:9`; also fed by `GenerationOptions.aspect_ratio`)
  - `resolution` (string; default `720p`)
- **Request body fields**: `model`, `prompt`, `duration`, `aspect_ratio`, `resolution`, and (for image-to-video) `image.url` = a base64 `data:` URI from the first attachment.
- **Negative prompt**: not forwarded — put exclusions in the prompt text.

## Example gallery (with why-it-works notes)

**Social product tease (text-to-video, vertical):**
```
A frosty energy drink can lands on a bar with a splash, ice spraying, quick
low push-in, high-energy, commercial ad style. Audio: can crack, fizz, punchy
bass drop.
```
Why: single subject + one motion, camera named, energetic style cue, tight audio — Grok's short-form wheelhouse.

**Animated character (image-to-video):**
```
The cartoon fox in the frame winks and gives a thumbs-up as stars sparkle
around it, gentle bounce, playful, anime style. Keep the character consistent.
Audio: cheerful chime, light crowd cheer.
```
Why: motion-only over a supplied still, "keep consistent", reusable style cue, native SFX.

**Atmosphere loop:**
```
Rain runs down a diner window at night, neon sign blurred behind the glass,
static camera, slow droplets, moody and lonely, cinematic. Audio: rain, low
distant jazz.
```
Why: one contained motion, strong mood + style words, concrete ambient audio; good for a looping backdrop.

## See Also

- `veo.md` — sibling implemented video provider (Google Veo), prefers denser cinematic prose + 4/6/8s clips.
- `runway-gen3.md`, `sora.md` — forward-looking video providers (not yet wired).
- `../use-case/creative-animation.md` — choosing video generation for a channel (if present).
