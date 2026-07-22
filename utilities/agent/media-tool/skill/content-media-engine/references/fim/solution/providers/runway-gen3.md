# Runway Gen-4 — motion-first text/image-to-video (forward-looking)

Runway's video generation model, the successor to the Gen-3 Alpha line. Strong at controllable motion, character/world consistency across shots, and image-to-video where a supplied still sets the look and the prompt drives only the movement. Runway is a paid SaaS (web app + API). This file is **forward-looking** — the file name says `gen3` for historical reasons, but the current generation is **Gen-4 / Gen-4.5**, and there is **no `runway` provider wired in media-tool today**.

**Current model**: Gen-4 (5s or 10s clips) and **Gen-4.5** (selectable 2–10s), plus **Gen-4 Turbo** for fast/cheap iteration. **Access**: paid SaaS (Runway web + API).
**Wired in media-tool as**: **NOT YET WIRED (forward-looking).** No `src/providers/runway.rs` exists; `get_provider("runway")` returns `None` and `is_stub_provider("runway")` is `true`. See Integration Notes for what a future provider would need.

> Version note (web-verified 2026-07): "Gen-3 Alpha" is superseded; author prompts to **Gen-4 / Gen-4.5**. Gen-4.5 exposes selectable duration 2–10s and improved camera/lighting understanding. Turbo trades quality for speed/cost.

## How This Model Reads Prompts

Runway's current guidance is **motion-first and positive-phrased**, and it differs sharply between the two modes:

- **Image-to-video** (the primary, highest-quality path): the input image already conveys subject, composition, color, lighting, and style — so the **prompt should describe almost entirely the motion**: what moves, how the camera behaves, and the temporal progression. Re-describing appearance fights the image.
- **Text-to-video**: describe **both** the visual scene **and** the motion, since there is no image to anchor the look.

Across both modes, Runway explicitly recommends **simpler prompts** (especially with a strong input image) and **positive over negative** phrasing — say "a single person walking alone," not "no other people." Good prompting is about clearly directing motion, camera behavior, and timing — not stuffing descriptive keywords.

Ideal length: **short and directive** — one or two clean sentences of motion/camera for image-to-video; a compact scene + motion description for text-to-video.

## Prompt Grammar / Syntax

Natural-language, no weighting/flag mini-language. Motion and camera are described in plain English; Gen-4/4.5 understand film-camera terminology and lighting physics well.

Image-to-video (motion only):
```
The camera slowly pushes in as she turns her head toward the window; dust
motes drift through the light. Subtle, steady motion.
```

Text-to-video (scene + motion):
```
A lone red kayak cuts across a glassy alpine lake at dawn, mist rising off
the water, mountains behind. Slow aerial pull-back revealing the full valley.
Calm, cinematic, cool morning light.
```

Motion/camera vocabulary that reads reliably: push-in, pull-back, pan, tilt, orbit, tracking shot, crane, handheld; plus temporal cues ("then", "as", "slowly", "suddenly") to sequence beats within the clip.

## How-To (worked recipes)

### How to prompt image-to-video (the strong path)
Supply a strong still; describe **only motion + camera**:
```
Gentle handheld drift to the right; the character blinks and exhales; steam
rises from the mug. Keep the motion subtle and continuous.
```
Note: with a good input image, less is more — do not restate hair/clothing/scene; that's the image's job.

### How to prompt text-to-video (no image)
Describe the scene **and** the motion in one compact block:
```
A vintage train pulls into a fog-wrapped station at night, headlamp cutting
the mist, steam billowing. Slow low-angle tracking shot alongside the
carriages. Moody, cinematic, warm platform lights.
```
Note: text-to-video must carry both look and motion; keep it to the essentials so the model isn't overloaded.

### How to direct the camera and time events
Chain beats with temporal words to choreograph within the clip:
```
Static wide shot; then the camera slowly cranes up as the dancer leaps,
holding on her at the apex. Soft rim light, shallow depth of field.
```
Note: Gen-4.5 handles "then / as / holding on" sequencing — use it to place a beat, not to cram in a scene change.

### How to use positive phrasing instead of negatives
Convert exclusions into what you *do* want:
```
An empty cobblestone alley at night, a single street lamp lit, one cat
crossing the frame.
```
Note: Runway's own guide prefers "a single person walking alone" over "no crowds" — describe the desired state directly.

### How to pick duration / model tier
Duration is a UI/API field (2–10s on Gen-4.5; 5 or 10s on Gen-4). Choose Turbo for cheap iteration, standard for final:
```
model: gen-4.5   duration: 6s   (iterate on gen-4-turbo, finalize on gen-4.5)
```
Note: these are request-side settings, not prompt tokens.

### How to keep a character consistent across shots
Reuse the **same input image / references** and keep the motion prompts short:
```
[shot A, same reference] She turns from the window and walks toward the door.
[shot B, same reference] Close on her hand as it reaches the handle.
```
Note: Gen-4's headline strength is cross-shot consistency — anchor every shot on the same reference rather than re-describing the person.

## Worked prompt templates (prep agent)

**Image-to-video (motion only):**
```
[CAMERA MOVE]; [SUBJECT MOTION beat]; [secondary motion / atmosphere].
Keep the motion [subtle|dynamic] and continuous.
```
Filled:
```
Slow push-in; she lifts her gaze and the wind stirs her hair; leaves drift
past. Keep the motion subtle and continuous.
```

**Text-to-video (scene + motion):**
```
[SCENE with key visuals], [SUBJECT], [MOTION + CAMERA]. [Mood/lighting].
```
Filled:
```
A lone red kayak on a glassy alpine lake at dawn, mist rising, slow aerial
pull-back revealing the valley. Calm, cool morning light.
```

## Prep-agent checklist (before emitting a Runway prompt)

- [ ] Correct mode: image-to-video → **motion only**; text-to-video → **scene + motion**.
- [ ] Short and directive (Runway rewards simplicity).
- [ ] Exclusions phrased **positively** (no negative-prompt reflex).
- [ ] Camera + motion named; beats sequenced with "then/as" if needed.
- [ ] Same reference image reused for a consistent series.
- [ ] Duration/model tier chosen as request fields (verify against live API docs).

## Do's and Don'ts

### ✅ Do
- Lead with **motion + camera**; in image-to-video, describe *only* that.
- Keep prompts **short and directive** — Runway explicitly rewards simplicity.
- Use **positive phrasing** for exclusions.
- Sequence beats with temporal words ("then", "as", "slowly").
- Iterate on **Turbo**, finalize on the full model.

### ❌ Don't
- Don't restate appearance in image-to-video — it competes with the input image.
- Don't write long keyword-stuffed prompts — they degrade Runway output.
- Don't lean on negative prompts — convert to positive descriptions.
- Don't request a full multi-scene story in one short clip — place one beat.
- Don't expect weighting/flag syntax — none exists.

## Negative Prompts / Exclusions

Runway's current guidance **de-emphasizes negative prompting** — the recommended approach is to state the desired scene positively rather than list what to exclude. Where an exclusion is unavoidable, phrase it as a positive constraint ("a single subject", "an empty road"). A future media-tool integration should treat `negative_prompt` as low-priority for Runway and prefer folding constraints into the positive prompt.

## Styling & Control

- **Input image is the primary style control** for image-to-video — pick/generate the still deliberately; the video inherits its look.
- **Camera + motion language** is the main lever; Gen-4/4.5 read cinematographic terms accurately.
- **Duration & model tier** are selectable (Gen-4.5: 2–10s; Turbo vs standard for speed/quality).
- **Consistency**: Gen-4 is notably better at keeping characters/worlds coherent across shots — reuse the same input image / references for a series.
- No sampler/CFG/seed surface is documented for the caller in the same way as diffusion image models; control is image + language + duration.

## Aspect / Resolution / Duration Constraints

- **Duration**: Gen-4 = **5s or 10s**; Gen-4.5 = **selectable 2–10s**.
- **Resolution / aspect**: standard cinematic and social ratios (16:9, 9:16, 1:1) via the app/API; consult Runway's current API docs for exact resolution tiers at integration time (do not hard-code — verify).
- **Modes**: text-to-video and image-to-video today; Runway signals additional input controls arriving.

## Common Pitfalls & Troubleshooting

- **Over-prompting**: the most common failure — verbose keyword prompts make Runway worse, not better. Simplify.
- **Appearance drift in i2v**: caused by re-describing the subject; describe motion only.
- **Negative-prompt reflex**: listing exclusions underperforms positive phrasing here.
- **Mode confusion**: using a text-to-video-style full-scene prompt in image-to-video wastes tokens and fights the image.
- **Version drift**: this file's name says `gen3`; the live model is Gen-4/4.5 — verify the exact model id and limits against Runway's API docs when wiring.

## Integration Notes (media-tool specific)

**NOT YET WIRED.** There is no `src/providers/runway.rs`. To integrate, a future provider would need to:

- Add a `runway` arm to `get_provider` in `src/providers/mod.rs` returning a `RunwayProvider` implementing `MediaProvider`, and remove `runway` from the stub set (`is_stub_provider`).
- Add an `api_key_env("runway")` mapping — Runway uses its own key (e.g. a `RUNWAYML_API_SECRET` / `RUNWAY_API_KEY`; **confirm the exact env-var name against Runway's current API docs** — do not assume).
- Add a `constraints("runway")` entry with the real prompt/character limit once confirmed.
- Add `default_model("runway")` (e.g. a `gen-4.5` / `gen-4-turbo` id — verify the exact string).
- Follow the established async pattern (submit → poll task → download) like `veo.rs` / `grok_video.rs`: Runway is task-based with polling.
- Read `provider_options` for duration, aspect ratio, and model tier; send the first attachment as the image-to-video input; map `GenerationOptions.duration_seconds` to Runway's duration field.
- Add `runway` candidates to `candidates_for(AssetType::Video, …)` if it should participate in automatic selection.

## Example gallery (with why-it-works notes)

**Image-to-video, subtle (strong path):**
```
Slow push-in; the candle flame flickers and wax drips; a thin ribbon of
smoke curls upward. Keep the motion subtle and continuous.
```
Why: motion-only over a supplied still, one contained beat, no appearance re-description — Runway's best-quality mode.

**Text-to-video, cinematic:**
```
A vintage motorcycle carves along a coastal cliff road at sunset, dust
kicking up, camera tracking low beside the wheels. Warm backlight, long
shadows, cinematic.
```
Why: scene + motion both present (no image to anchor look), camera named, single continuous action.

**Consistency series (same reference across shots):**
```
[shot 1, ref X] The knight raises her visor and surveys the valley.
[shot 2, ref X] She turns and strides toward the gate.
```
Why: reusing one reference is Gen-4's identity lock; short motion prompts avoid drift.

## Quick camera / motion vocabulary (reads reliably)

Camera: push-in, pull-back, pan, tilt, orbit, tracking shot, crane, handheld drift, static.
Motion tempo: slowly, steadily, suddenly, drifting, subtle, dynamic.
Sequencing: "then", "as", "holding on" — place one beat, don't cut scenes.

## See Also

- `veo.md`, `grok-video.md` — the currently implemented video providers (use these today).
- `sora.md` — sibling forward-looking video provider (OpenAI Sora, also not yet wired).
- `../use-case/creative-animation.md` — choosing video generation for a channel (if present).
