# Suno — full-song music generation from a style brief + structured lyrics

Suno is a paid-SaaS music-generation model that turns a short **style description** plus optional **lyrics with structure tags** into a complete, mixed song (vocals + instrumentation). It is the strongest general-purpose "type a vibe, get a finished track" model. You do NOT describe audio like an image prompt — you supply two distinct fields: a compact *style* brief (genre/mood/instruments/tempo) and a *lyrics* body whose bracketed section tags drive the arrangement. In media-tool this is the **only implemented music provider**, wired as `service: suno` (music) and the same service with a SFX model for sound effects.

**Current model**: Suno v5.5 (`V5_5`) — web-verified current major as of 2026-07; v5.5 shipped March 2026 adding Voices / Custom Models / "My Taste" with **no change to the meta-tag vocabulary**. **Access**: paid SaaS via API wrapper.
**Wired in media-tool as**: `service: suno` (see `src/providers/suno.rs`). Music model `V5_5`; SFX routes through `V5_SOUND` → the `/generate/sounds` endpoint.

> Version note (web-verified 2026-07): The tag grammar (`[Verse]`, `[Chorus]`, vocal cues in parentheses) is unchanged from v4 through v5.5 — v4.5+ simply reads more conversational style text and holds a longer style field (~1000 chars vs ~200 on v4). Sources: [Suno Guide V5.5 (Blake Crosley)](https://blakecrosley.com/guides/suno), [Suno AI Metatags Guide 2026 (OpenMusicPrompt)](https://openmusicprompt.com/blog/suno-ai-metatags-guide), [Suno Meta Tags & Structure (Jack Righteous)](https://jackrighteous.com/en-us/pages/suno-ai-meta-tags-guide).

## How This Model Reads Prompts

Suno reads **two separate channels**, and the biggest prep mistake is collapsing them into one blob:

1. **Style / description** — a compact brief of *genre → mood/energy → vocal character → key instruments → production/tempo*. Lead with genre + subgenre; it anchors everything. v4.5+ handles 6–7 descriptors comfortably; keep it tight (a ~200-word / ~1000-char sweet spot, not a paragraph of prose).
2. **Lyrics** — the actual words to be sung, segmented by bracketed **structure tags**. This is where arrangement is controlled, not in the style field.

- **What it weights most**: the **first genre/subgenre token** in the style field, and the **structure tags** in the lyrics. Front-load genre; everything after refines it.
- **Ordering (style field)**: `[Genre/Subgenre], [Tempo/Energy/BPM], [Key instruments], [Vocal style], [Production/Mood], [Modifiers]`.
- **Instrumental vs vocal**: media-tool's Suno provider defaults `instrumental = true` unless you set it false — so for a *song with vocals* the prep MUST signal vocals (see Integration Notes) and supply lyrics.

## Prompt Grammar / Syntax

Suno's real surface is **bracketed structure/meta tags** inside the lyrics, plus **parenthetical vocal cues**. There is no `(word:1.3)` weighting or `--flag` grammar.

**Structure tags** (drive arrangement):
```text
[Intro] [Verse] [Pre-Chorus] [Chorus] [Post-Chorus] [Bridge]
[Hook] [Break] [Interlude] [Instrumental] [Refrain] [Outro]
```

**Vocal / performance cues** (parentheses, inline in lyrics):
```text
(whispered) (belted) (spoken word) (harmonized) (ad-lib) (falsetto)
```

**Meta / production tags** also go in brackets to steer feel between sections, e.g. `[Build]`, `[Drop]`, `[Guitar Solo]`, `[Key Change]`, `[Fade Out]`. Instrument/section names in brackets are hints, not guarantees.

Minimal style field:
```text
Dream pop, mid-tempo, shimmering reverb-drenched guitars, breathy female vocals, warm analog production, nostalgic
```

Minimal lyrics body:
```text
[Intro]
(instrumental, soft synth pad)

[Verse]
Streetlights blur into the rain tonight
Every window holds a stranger's light

[Chorus]
And I keep driving, keep driving home
Through the neon and the monochrome
```

## How-To (worked recipes)

### How to write a vocal pop song (style + lyrics split)
Problem: you want sung lyrics, not an instrumental.
```text
STYLE:  Synth-pop, upbeat 118 BPM, punchy sidechained bass, bright female lead vocal, glossy modern production, euphoric
LYRICS:
[Verse]
We were counting down the city lights
[Pre-Chorus]
Hold your breath, the sky's about to break
[Chorus]
Run — we're electric tonight
```
Note: supply real lyrics AND ensure `instrumental=false` (see Integration Notes) — otherwise media-tool defaults to instrumental and ignores the words.

### How to produce a pure instrumental / background bed
Problem: you need a track with no singing (e.g. a video underscore).
```text
STYLE:  Lo-fi hip-hop, 82 BPM, dusty vinyl crackle, mellow Rhodes piano, boom-bap drums, relaxed study-beat mood, instrumental
LYRICS: [Intro] [Verse] [Chorus] [Outro]   ← structure only, no words
```
Note: keep the word `instrumental` in the style field and leave the lyrics as bare section tags (or empty). This is the media-tool default path.

### How to control song structure and dynamics
Problem: the arrangement rambles or never "drops."
```text
[Intro]
[Verse]
[Build]
[Chorus]
[Verse]
[Bridge]
[Guitar Solo]
[Chorus]
[Outro] (fade out)
```
Note: an explicit tag skeleton is the single most reliable arrangement control. Place `[Build]` before `[Chorus]` to force a lift; `[Outro] (fade out)` for a clean ending instead of an abrupt cut.

### How to steer vocals (gender / delivery)
Problem: you got the wrong vocal character.
```text
STYLE:  ...bright female lead vocal, layered harmonies...
LYRICS:
[Chorus]
(belted, harmonized) Hold the line, we're almost home
```
Note: state vocal gender/character in the *style* field, and use parenthetical cues in the *lyrics* for per-line delivery. media-tool also exposes a `vocalGender` option ("m"/"f") that maps to Suno's API field — prefer it when you want a hard signal.

### How to generate a short sound effect (SFX)
Problem: you need a one-shot sound, not a song.
```text
PROMPT: heavy wooden door creaking open slowly in an empty stone hall, single one-shot, no music
```
Note: SFX uses the `V5_SOUND` model → `/generate/sounds` endpoint with a **500-char** cap (vs 3000 for music). Keep it to a concrete acoustic description; `soundLoop`, `soundTempo`, `soundKey` options exist for loopable beds.

## Do's and Don'ts

### ✅ Do
- **Split style and lyrics** — compact brief in one field, words in the other.
- **Lead the style field with genre + subgenre.** It anchors the whole generation.
- **Always include a structure-tag skeleton** in the lyrics, even for instrumentals.
- **Name concrete instruments and a tempo/BPM** — "82 BPM dusty Rhodes" beats "chill vibes."
- **Set `instrumental=false` and supply lyrics** whenever you want singing.

### ❌ Don't
- **Don't cram a whole prose paragraph into the style field** — it dilutes the genre anchor; keep to ~1000 chars / ~6–7 descriptors.
- **Don't put lyrics in the style field or genre words in the lyrics** — they cross-contaminate.
- **Don't rely on defaults for vocals** — media-tool defaults to instrumental; silence-on-vocals is almost always this.
- **Don't over-tag** — a dozen competing `[Solo]/[Drop]/[Breakdown]` tags in a 60-second clip produces mush.
- **Don't expect exact BPM/key precision** — tags nudge, they don't clamp.

## Negative Prompts / Exclusions

Suno supports negative styling via a **negative-tags** field (media-tool maps `options.negative_prompt` → the API `negativeTags`). Put **styles/timbres to avoid** there, not lyric content: e.g. `distorted, aggressive, heavy metal, autotune`. Don't use it to try to remove words from lyrics — remove those from the lyrics body instead.

## Styling & Control

Beyond style text, media-tool exposes Suno's numeric/steering knobs through `provider_options`:
- **`styleWeight`** (float) — how hard to push the style description.
- **`weirdnessConstraint`** (float) — experimentation vs. safety of the arrangement.
- **`audioWeight`** (float) — weighting when an audio reference is involved.
- **`vocalGender`** — "m" / "f" hard signal.
- **`personaId` / `personaModel`** — Suno "persona"/voice continuity (v5.5 Voices feature) for a consistent singer across tracks.
- **`title`** — song title (custom mode).
These are optional; when omitted Suno uses its own defaults. Do NOT invent other numeric knobs — only the four floats above (`styleWeight`, `weirdnessConstraint`, `audioWeight`) plus weights are wired.

## Aspect / Resolution / Duration Constraints

- **No aspect ratio** (audio). The relevant constraint is **length**.
- **Style/prompt cap in media-tool**: **3000 chars** for music (`suno`), **500 chars** for SFX (`suno-sfx`). Suno's own style field is ~1000 chars on v4.5+, lyrics up to ~5000 — media-tool's 3000 covers the combined text it sends.
- **Duration**: pass `duration_seconds` (mapped to the API `duration` field). Suno generates full songs (roughly up to a few minutes); for a target clip length request it explicitly and use `[Outro] (fade out)` so it resolves rather than truncates.
- **Custom mode** auto-enables when a `style` option is present OR the prompt exceeds 200 chars — that's when the style/title/persona fields are honored.

## Common Pitfalls & Troubleshooting

- **"It came out instrumental."** media-tool defaults `instrumental=true`. Set it false and supply lyrics.
- **Wrong arrangement / no chorus.** You omitted structure tags — add an explicit `[Verse]/[Chorus]` skeleton.
- **Style ignored.** You may be in non-custom mode. Provide a `style` option or a prompt >200 chars so custom mode engages.
- **SFX truncated / rejected.** SFX path has a hard 500-char cap; trim to a single acoustic description.
- **Genre bleed.** Too many descriptors after the genre anchor pulls it off-target — cut to 6–7.
- **Async latency.** Generation is job-based (submit → poll); media-tool polls up to ~20 min. This is normal, not a hang.

## Integration Notes (media-tool specific)

- **`service: suno`**, provider in `src/providers/suno.rs`. API base is the third-party wrapper `https://api.sunoapi.org` (not Suno's first-party site), submit-then-poll (`/api/v1/generate` → `/api/v1/generate/record-info`).
- **API key**: env **`SUNO_API_KEY`** (see `api_key_env` in `src/providers/mod.rs`).
- **Models**: music default `V5_5`; SFX `V5_SOUND` (any model containing `SOUND`/`sfx`/`sound` routes to the sounds endpoint). Provider file's fallback constant is `V4_5ALL`, but the candidate/default wiring selects `V5_5`.
- **`provider_options` keys read**: `style`, `title`, `customMode`, `instrumental` (**defaults true**), `negativeTags` (or top-level `negative_prompt`), `vocalGender`, `styleWeight`, `weirdnessConstraint`, `audioWeight`, `personaId`, `personaModel`, `callBackUrl`; SFX-only: `soundLoop`, `soundTempo`, `soundKey`. Length: `duration_seconds`.
- **Char limits** (`constraints()` in mod.rs): `suno` → **3000**, `suno-sfx` → **500**.
- **Prep guidance**: emit the *style brief* as the main prompt text and, when vocals are wanted, ensure the pipeline passes lyrics + `instrumental=false`. Keep genre first.

## See Also
- `udio.md` — sibling music generator (NOT YET WIRED); different prompt emphasis (texture/production over structure).
- `elevenlabs.md`, `openai-tts.md`, `qwen-tts.md` — voice/TTS siblings (verbatim text, not style briefs).
- `../use-case/creative-animation.md` / `../use-case/media-processing.md` — where music/SFX assets are consumed (if present).
