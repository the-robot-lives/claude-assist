# ElevenLabs — high-fidelity TTS & voice cloning (verbatim text, not a style brief)

ElevenLabs is a paid-SaaS text-to-speech / voice-cloning model. The single most important prep rule: **the prompt IS the words to be spoken, verbatim.** Unlike image/music models, ElevenLabs does not "interpret" a description — it reads your text aloud in the chosen voice. Voice character, emotion, and delivery are controlled by the **voice ID**, the **model**, and **numeric settings** (options), NOT by describing the voice in the prompt. In media-tool this is the top-tier voice provider, wired as `service: elevenlabs`.

**Current model**: Eleven v3 (alpha) is the newest, most expressive model with **audio tags** and 70+ languages; **Eleven Multilingual v2** (`eleven_multilingual_v2`) is the stable production default; **Flash v2.5** is the low-latency option. **Access**: paid API.
**Wired in media-tool as**: `service: elevenlabs` (see `src/providers/elevenlabs.rs`), default model `eleven_multilingual_v2`, default voice "Rachel" (`21m00Tcm4TlvDq8ikWAM`).

> Version note (web-verified 2026-07): Core TTS models are `eleven_v3` (expressive, alpha, supports `[audio tags]`), `eleven_multilingual_v2` (stable default), and `eleven_flash_v2_5` (fast). v3's headline feature is bracketed audio tags like `[whispers]`, `[excited]`, `[sighs]`. Sources: [ElevenLabs Models docs](https://elevenlabs.io/docs/overview/models), [Eleven v3 Audio Tags blog](https://elevenlabs.io/blog/v3-audiotags), [ElevenLabs Cheat Sheet 2026](https://www.webfuse.com/elevenlabs-cheat-sheet).

## How This Model Reads Prompts

The prompt is **literal speech text**. It reads what you write, character for character. Therefore:

- **Write clean, punctuated prose** — punctuation is prosody. Commas = short pauses, periods = full stops, `—` = a longer break, `...` = a trailing pause. Question marks and exclamation points shape intonation.
- **Spell for the ear.** Expand what should be spoken in full ("Dr." → "Doctor", "2026" → "twenty twenty-six" if you want it said that way, "API" stays "A P I" or write "a-p-i" to force letters).
- **Do NOT put stage directions in the text for v2 models** — "(in a cheerful voice) Hello" will literally speak "in a cheerful voice." Delivery belongs in *settings*, or (on **v3 only**) in bracketed **audio tags**.
- **Length**: there is no "sweet spot" of description — write exactly the passage you want spoken. Very long passages are fine but generate in one pass; chunk multi-paragraph scripts if you need per-segment voices.

## Prompt Grammar / Syntax

Two regimes depending on model:

**v2 / Flash (stable):** plain text only. Control = voice settings (below). No in-text markup beyond punctuation.
```text
Welcome aboard. Please keep your seatbelt fastened — we'll be departing shortly.
```

**v3 (alpha):** supports **audio tags** — bracketed emotion/action cues the model performs rather than speaks:
```text
[warmly] Welcome aboard. [pause] Please keep your seatbelt fastened, [reassuring] we'll be moving shortly.
```
Common v3 tags: `[whispers] [excited] [sighs] [laughs] [sad] [shouting] [pause]` and sound cues like `[clapping]`. **Only use audio tags when the model is `eleven_v3`** — on v2 they are read aloud as text.

There are **no** `(word:1.3)` weights, LoRA, or `--flags`. Voice choice is a **voice_id**, not a name in the prompt.

## How-To (worked recipes)

### How to speak a line in a specific cloned/preset voice
Problem: you need a particular narrator.
```text
TEXT (prompt): The results are in, and they exceeded every projection.
OPTION: voice_id = "21m00Tcm4TlvDq8ikWAM"   (or your cloned voice's ID)
```
Note: the voice is selected entirely by `voice_id` in options — never by describing "a deep male voice" in the prompt text.

### How to control emotion / delivery
Problem: it sounds flat, or you want it expressive.
```text
v3:  [excited] We did it — [laughs] we actually did it!
v2:  We did it — we actually did it!   + OPTION: stability = 0.3 (Creative)
```
Note: on v3 use audio tags; on v2 lower `stability` toward the Creative end for more emotion (higher = more monotone/robust). Delivery is settings/tags, never prose description.

### How to make the voice more consistent (or more expressive)
Problem: the clone drifts or hallucinates.
```text
OPTIONS: stability = 0.7   similarity_boost = 0.85   use_speaker_boost = true
```
Note: higher `stability` (toward Robust) = steadier but less responsive to direction; lower (Creative ~0.3) = more emotional but can hallucinate; ~0.5 (Natural) balances. `similarity_boost` pushes fidelity to the reference voice.

### How to pick language / multilingual output
Problem: non-English text or accent control.
```text
TEXT: Bonjour et bienvenue à bord.
OPTIONS: model = "eleven_multilingual_v2"   language_code = "fr"
```
Note: use a multilingual model (`eleven_multilingual_v2` or `eleven_v3`); `language_code` pins the language when text is ambiguous.

### How to hit a specific audio format / speaking rate
Problem: you need WAV, or a slower read.
```text
OUTPUT PATH: narration.wav   → media-tool selects wav_44100 automatically
OPTIONS: speed = 0.9   (slightly slower; ~0.7–1.2 range)
```
Note: format is chosen from the output file extension (see Integration Notes); `speed` is a voice-setting float, not in-text.

## Do's and Don'ts

### ✅ Do
- **Put the exact spoken words in the prompt** — nothing else.
- **Use punctuation as your prosody tool.**
- **Select voice via `voice_id`; set emotion via `stability`/audio tags.**
- **Match model to need**: `eleven_v3` for expressive tag-driven reads, `eleven_multilingual_v2` for reliable production, Flash for latency.
- **Expand abbreviations/numbers** the way you want them pronounced.

### ❌ Don't
- **Don't describe the voice in the text** ("in a warm voice, say...") — it will be spoken literally on v2.
- **Don't use `[audio tags]` on v2/Flash** — only `eleven_v3` performs them; elsewhere they're read aloud.
- **Don't push `stability` to 0 for narration** — Creative mode hallucinates on long text.
- **Don't rely on the prompt to change language** — set `model` + `language_code`.
- **Don't paste raw markdown/HTML** — symbols get vocalized.

## Negative Prompts / Exclusions

There is **no negative-prompt field** for TTS — you're providing exact speech, so "exclusion" means simply not writing those words. To suppress artifacts (mispronunciations, spurious sounds), adjust `stability` upward and clean the input text rather than reaching for a negative prompt. media-tool does not send `negative_prompt` to ElevenLabs.

## Styling & Control

media-tool maps these `provider_options` into ElevenLabs `voice_settings`/body:
- **`voice_id`** — which voice (preset or cloned). Defaults to Rachel.
- **`stability`** (0–1) — Creative(low) ↔ Natural(~0.5) ↔ Robust(high).
- **`similarity_boost`** (0–1) — fidelity to the reference voice.
- **`style`** (0–1, float) — style exaggeration (model-dependent).
- **`speed`** — speaking rate.
- **`use_speaker_boost`** (bool) — clarity/consistency boost.
- **`language_code`**, **`seed`** (determinism where supported).
Note `style` here is a **numeric slider in options**, not a text field — do not put a style *description* in the prompt.

## Aspect / Resolution / Duration Constraints

- **No aspect ratio** (audio). Duration is implicit — it's however long the text takes to speak; there is no `duration_seconds` control (the provider does not read it).
- **Output format** is derived from the output file extension: `.wav`→`wav_44100`, `.ogg`/`.opus`→`opus_48000_128`, `.pcm`→`pcm_44100`, otherwise `mp3_44100_128`.
- **No media-tool char cap** is set for elevenlabs in `constraints()` (returns `None`) — but keep individual requests to a sane passage; chunk long scripts.

## Common Pitfalls & Troubleshooting

- **Stage directions spoken aloud** → you used v2 with bracket/paren cues; switch to `eleven_v3` or move delivery to `stability`.
- **Clone sounds "off"** → raise `similarity_boost` and `stability`; verify the correct `voice_id`.
- **Robotic/monotone** → `stability` too high; lower toward 0.4–0.5.
- **Hallucinated words on long text** → `stability` too low (Creative); raise it, or split the text.
- **Wrong language/accent** → set `model=eleven_multilingual_v2` + `language_code`.
- **Numbers/abbreviations mispronounced** → spell them out in the input text.
- **401/403** → check `ELEVENLABS_API_KEY`.

## Integration Notes (media-tool specific)

- **`service: elevenlabs`**, provider in `src/providers/elevenlabs.rs`. Endpoint `https://api.elevenlabs.io/v1/text-to-speech/{voice_id}` with `xi-api-key` header.
- **API key**: env **`ELEVENLABS_API_KEY`** (see `api_key_env` in `mod.rs`).
- **Default model** `eleven_multilingual_v2`; **default voice** Rachel `21m00Tcm4TlvDq8ikWAM`.
- **`provider_options` keys read**: `voice_id`, `stability`, `similarity_boost`, `style` (float), `speed`, `use_speaker_boost`, `language_code`, `seed`. Output format inferred from file extension. Attachments and `negative_prompt` are **not** used.
- **Char limit**: none set in `constraints()` (`max_prompt_chars = None`).
- **Prep guidance**: emit the **verbatim speech** as the prompt; route all voice/emotion/format decisions into `provider_options`, not the text. For expressive tag-driven reads, set `model=eleven_v3` and use `[audio tags]`; otherwise leave the text clean.

## See Also
- `openai-tts.md`, `qwen-tts.md` — sibling TTS providers (same verbatim-text principle; different control surfaces).
- `suno.md` / `udio.md` — music siblings (style briefs, not verbatim speech).
- `../use-case/media-processing.md` — narration/voiceover consumption (if present).
