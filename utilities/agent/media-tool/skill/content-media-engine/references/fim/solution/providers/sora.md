# OpenAI Sora — storyboard-driven narrative video (forward-looking)

OpenAI's video generation model. Strong at longer, narrative multi-shot clips, physically coherent scenes, and a **storyboard workflow** where several prompts are sequenced into one multi-shot piece. Prompting is cinematographer-style: describe each shot as if briefing a crew that has never seen your storyboard. Sora is a paid product (Sora app + API). This file is **forward-looking** — there is **no `sora` / OpenAI-video provider wired in media-tool today**.

**Current model**: **Sora 2** and **Sora 2 Pro** (Pro adds higher resolutions and per-second pricing tiers). Clips of ~**15–25 seconds**; storyboard editor sequences multiple prompts. **Access**: paid SaaS (Sora app + OpenAI API).
**Wired in media-tool as**: **NOT YET WIRED (forward-looking).** No `src/providers/sora.rs`; `get_provider("sora")` returns `None` and `is_stub_provider("sora")` is `true`. Note: the OpenAI **key** already exists in the repo for `openai-tts`/`openai-chat` (`OPENAI_API_KEY`) — a Sora provider would reuse it. See Integration Notes.

> Version note (web-verified 2026-07): current is **Sora 2 / Sora 2 Pro** (Sora 1's ~6s limit is superseded; 15–25s now). The API exposes create/extend/edit video and character endpoints. Verify exact model ids, sizes, and pricing against OpenAI's current docs at integration time.

## How This Model Reads Prompts

Sora reads **detailed, storyboard-style natural language**. The mental model OpenAI recommends: **brief a cinematographer who has never seen your storyboard** — if you omit a detail, the model improvises and you may not get your intent. For each shot, state:

1. **Camera framing** (shot size, angle, lens feel).
2. **Depth of field** (deep focus vs. shallow, rack focus).
3. **Action in beats** — describe the motion as an ordered sequence, not a single verb.
4. **Lighting and palette** — mood, color, time of day.

Sora tolerates (and rewards) **more detail than Grok** and supports **longer clips**, but it "follows instructions more reliably in shorter clips" — so for precise results, keep a single shot tight and use the **storyboard editor** to chain shots rather than cramming a whole story into one long prompt.

Ideal approach: **one clear shot per prompt block**, beats sequenced in order; assemble multi-shot narratives via the storyboard, not via one over-stuffed request.

## Prompt Grammar / Syntax

Natural-language prose, no weighting/flag syntax. Structure a shot like a storyboard cell:

```
Shot:      Medium tracking shot, slight low angle, 35mm feel.
Focus:     Shallow depth of field, subject sharp, background bokeh.
Action:    She pushes open the door, pauses, then steps into the rain.
Lighting:  Overcast blue-grey daylight, wet-street reflections.
Audio:     Rain, distant traffic, a door hinge creak.
```

You can write it as flowing prose too — the labels above are for clarity, not required tokens:
```
Medium tracking shot at a slight low angle, shallow depth of field. She pushes
open the door, pauses, then steps into the rain. Overcast blue-grey light,
reflections on wet cobblestones. Rain and distant traffic on the soundtrack.
```

Multi-shot: write each shot as its own prompt in the **storyboard editor**; keep continuity by repeating character and setting descriptors (or using the character endpoint) across cells.

## How-To (worked recipes)

### How to write one shot like a storyboard cell
Cover framing, focus, beats, lighting in order:
```
Wide establishing shot, camera static. A neon diner glows on an empty desert
highway at night. A single car pulls in; headlights sweep across the lot;
the engine cuts. Cool moonlight, warm neon spill, deep focus.
```
Note: state framing and lighting explicitly — omissions get improvised.

### How to describe action in beats
Sequence the motion rather than using one verb:
```
He sits at the piano, flexes his hands, then begins to play; the camera slowly
pushes in as his expression softens.
```
Note: "then / as" beats give Sora a timeline to animate within the clip.

### How to build a multi-shot narrative
Use the storyboard editor — one prompt per shot, consistent descriptors for continuity:
```
[Shot 1] Wide: the lighthouse at dawn, gulls circling, slow crane up.
[Shot 2] Medium: the keeper (grey beard, yellow slicker) climbs the stairs.
[Shot 3] Close: his weathered hand strikes a match, warm flame glow.
```
Note: repeat the character description (or use the character feature) so the person stays consistent across cells; don't try to encode all three shots in one prompt.

### How to keep instructions reliable
Prefer a **shorter, precise** shot when accuracy matters; extend/chain for length:
```
Keep this shot to one action: "the balloon lifts off the table and floats up."
Then use Extend to continue the motion into the next beat.
```
Note: OpenAI notes shorter clips follow instructions more faithfully — split, then extend.

### How to target size / duration
Duration and resolution are request/UI fields, not prompt text:
```
size: 1280x720 (landscape) or 720x1280 (portrait); Pro adds 1024x1792 / 1792x1024
duration: pick the shorter end for precise control; extend for length
```
Note: verify the exact supported sizes/durations against OpenAI's current API docs when wiring.

### How to hold a character identity across a whole piece
Create a reusable character once, then reference it per shot:
```
Character: "Mara" — mid-30s, close-cropped silver hair, olive flight jacket,
faint scar over left brow.
[Shot 1] Wide: Mara steps off the transport onto a windy platform.
[Shot 2] Close: Mara scans the crowd, jaw tight.
```
Note: the character endpoint is the most reliable identity lock — stronger than repeating a text description, and it survives across shots and extends.

## Worked prompt template (prep agent, one shot per block)

```
[SHOT SIZE + ANGLE + lens feel]. [Depth of field]. [ACTION in ordered beats:
X, then Y, then Z]. [Lighting + palette + time of day]. Audio: [ambient],
[SFX][; "<short line>"].
```

Filled:
```
Medium tracking shot, slight low angle, 35mm feel. Shallow depth of field.
She pushes open the door, pauses on the threshold, then steps into the rain.
Overcast blue-grey daylight, reflections on wet cobblestones. Audio: rain,
distant traffic, a hinge creak.
```

## Prep-agent checklist (before emitting a Sora prompt)

- [ ] Every shot specifies framing, focus, lighting — no gaps left to improvise.
- [ ] Action written as **ordered beats** ("then/as"), not one verb.
- [ ] One shot per prompt; multi-shot → storyboard, not a mega-prompt.
- [ ] Shorter clip when precision matters; extend for length.
- [ ] Character identity locked via the character endpoint or repeated descriptors.
- [ ] Exclusions phrased positively, inside the shot description.
- [ ] Size/duration set as request fields; values verified against live docs.

## Do's and Don'ts

### ✅ Do
- Describe **each shot fully** — framing, focus, beats, lighting — like a storyboard cell.
- Sequence **action in beats** ("then", "as") to give a timeline.
- Use the **storyboard editor** for multi-shot narratives; one prompt per shot.
- Keep a shot **shorter** when instruction-following precision matters, then extend.
- Repeat character/setting descriptors across shots for continuity.

### ❌ Don't
- Don't leave framing or lighting unspecified — Sora improvises the gaps.
- Don't stuff a full multi-shot story into a single long prompt — reliability drops.
- Don't expect weighting/flag syntax — it's plain prose.
- Don't assume Sora 1's 6s limit — current is 15–25s (but shorter = more faithful).
- Don't hard-code sizes/prices from memory — verify against live docs (they shift).

## Negative Prompts / Exclusions

Sora is prose-driven; there is no emphasized weighted negative field in the storyboard workflow. Express exclusions **positively inside the shot description** ("an empty street", "a single subject") rather than as a negation list. A future integration should treat exclusions as prompt-embedded, not a separate parameter.

## Styling & Control

- **Cinematographic language** is the main control surface — framing, lens feel, depth of field, camera moves, lighting, palette.
- **Storyboard editor**: sequence shots; the primary tool for narrative control and pacing.
- **Character endpoint** (`POST /v1/videos/characters`): create a reusable character to hold identity constant across shots — the strongest consistency lever.
- **Extend / Edit** endpoints: `POST /v1/videos/extensions` continues a clip; `POST /v1/videos/{id}/edits` revises — build length and iterate without regenerating from scratch.
- **Resolution tier** (Sora 2 vs Sora 2 Pro) affects detail/texture fidelity and cost.

## Aspect / Resolution / Duration Constraints

- **Duration**: ~**15–25 seconds** per generation (Sora 2); shorter clips follow instructions more reliably; chain via Extend for longer pieces.
- **Resolution / size** (Sora 2 Pro, per OpenAI): landscape **1280x720**, portrait **720x1280**, plus **1024x1792** and **1792x1024**; higher sizes render detail/lighting better at higher cost. **Confirm current sizes at integration time.**
- **Pricing** (Pro, per OpenAI, indicative): roughly **$0.30–$0.70 per second** by resolution — cost scales with length × resolution; budget accordingly.

## Common Pitfalls & Troubleshooting

- **Under-specification**: the #1 failure — unstated framing/lighting gets improvised. Brief every shot fully.
- **Long-prompt reliability drop**: cramming a whole story into one prompt reduces adherence; storyboard + extend instead.
- **Continuity breaks across shots**: fix by repeating descriptors or using the character endpoint.
- **Content filtering**: OpenAI blocks explicit content, real public figures, and some IP; expect refusals — soften the subject.
- **Cost surprises**: per-second pricing × higher resolution adds up fast on 25s Pro clips.
- **Version/spec drift**: model ids, sizes, and prices move — verify against OpenAI docs before wiring, don't trust cached numbers.

## Integration Notes (media-tool specific)

**NOT YET WIRED.** There is no `src/providers/sora.rs`. To integrate, a future provider would need to:

- Add a `sora` (or `openai-video`) arm to `get_provider` in `src/providers/mod.rs` returning a provider implementing `MediaProvider`, and remove it from the stub set (`is_stub_provider`).
- Reuse the existing OpenAI key: `api_key_env` already maps `openai-tts` / `openai-chat` → `OPENAI_API_KEY`; add the same mapping for `sora`.
- Follow the async submit-and-poll pattern (`veo.rs` / `grok_video.rs`): `POST /v1/videos` to create, poll the video id for completion, then download; optionally support `/v1/videos/extensions` and `/v1/videos/characters`.
- Add `constraints("sora")` with the real prompt/character limit, `default_model("sora")` (e.g. a `sora-2` / `sora-2-pro` id — **verify the exact string**), and read `provider_options` for `size`/resolution, duration, and (optionally) a character reference.
- Map `GenerationOptions.duration_seconds` to Sora's duration; map the first attachment to an image/first-frame input where the API supports it.
- Add `sora` candidates to `candidates_for(AssetType::Video, …)` if it should participate in automatic selection (likely a High-quality entry given cost).

## Example gallery (with why-it-works notes)

**Single cinematic shot:**
```
Wide establishing shot, camera static, deep focus. A neon diner glows on an
empty desert highway at night; a single car pulls in, headlights sweeping the
lot, then the engine cuts. Cool moonlight, warm neon spill. Audio: crickets,
a ticking engine, faint jukebox.
```
Why: framing + focus + lighting all specified, action in ordered beats, concrete audio — no gaps for Sora to improvise.

**Storyboard sequence (three cells, one prompt each):**
```
[Shot 1] Wide, slow crane up: the lighthouse at dawn, gulls circling.
[Shot 2] Medium: the keeper (grey beard, yellow slicker) climbs the stairs.
[Shot 3] Close, shallow focus: his weathered hand strikes a match, warm glow.
```
Why: one shot per prompt, character descriptor repeated for continuity, pacing controlled by the storyboard rather than a mega-prompt.

**Dialogue moment (short clip for fidelity):**
```
Medium close-up, shallow focus. A nervous intern clutches a coffee and says,
"They want the numbers by noon?" Fluorescent office light, muted palette.
Audio: keyboard clatter, HVAC hum.
```
Why: kept short (instruction-following is higher on brief clips), one quoted line, framing + lighting + audio all set.

## Quick shot-brief vocabulary (Sora reads these well)

Framing: extreme wide, wide, medium, medium close-up, close-up, extreme close-up; low/high/eye-level angle.
Focus: deep focus, shallow depth of field, rack focus, macro.
Camera: static, push-in, pull-back, crane up/down, tracking, orbit, handheld.
Sequencing: describe beats with "then/as"; assemble shots in the storyboard editor.

## See Also

- `veo.md`, `grok-video.md` — the currently implemented video providers (use these today).
- `runway-gen3.md` — sibling forward-looking video provider (Runway Gen-4, also not yet wired).
- `../use-case/creative-animation.md` — choosing video generation for a channel (if present).
