# OpenAI TTS — verbatim speech with a natural-language "instructions" steer

OpenAI's text-to-speech reads your text aloud in a chosen preset voice. Its distinctive control is the **`instructions` field**: a *separate* natural-language directive ("speak in a calm, sympathetic tone") that steers delivery **without being spoken**. So prep produces two things: the **verbatim text** (the words) and, optionally, an **instructions** string (how to say them). In media-tool this is a mid-tier voice provider, wired as `service: openai-tts`.

**Current model**: `gpt-4o-mini-tts` — the current-generation, steerable, low-cost TTS model (13 built-in voices, supports `instructions`). Legacy `tts-1` / `tts-1-hd` still exist but **do not** support `instructions`. **Access**: paid API.
**Wired in media-tool as**: `service: openai-tts` (see `src/providers/openai_tts.rs`), default model `gpt-4o-mini-tts`, default voice `alloy`.

> Version note (web-verified 2026-07): `gpt-4o-mini-tts` is the shipping steerable model; voices are `alloy, ash, ballad, coral, echo, fable, onyx, nova, sage, shimmer, verse, marin, cedar`. `instructions` controls *how* text is spoken and does **not** work on `tts-1`/`tts-1-hd`. Max input ~2000 tokens. Sources: [OpenAI Text-to-Speech guide](https://developers.openai.com/api/docs/guides/text-to-speech), [gpt-4o-mini-tts model page](https://developers.openai.com/api/docs/models/gpt-4o-mini-tts), [Introducing next-gen audio models](https://openai.com/index/introducing-our-next-generation-audio-models/).

## How This Model Reads Prompts

The prompt (`input`) is **literal speech text**. Two channels:

1. **`input`** — the exact words spoken, verbatim. Punctuation shapes prosody (commas/periods/dashes = pauses and stops).
2. **`instructions`** (optional, `gpt-4o-mini-tts` only) — a plain-English delivery directive that is **not** vocalized. This is where tone, pacing, accent, and character go.

- **Don't put delivery notes in `input`** — they'll be read aloud. Put them in `instructions`.
- **Length**: write the passage you want spoken; input is capped around **2000 tokens** — chunk longer scripts.
- **Voice** is a preset name in options, not a description in the text.

## Prompt Grammar / Syntax

No markup grammar in the text. Control is the split between `input` and `instructions`, plus the `voice` preset.

**Plain read:**
```text
input: "Your order has shipped and will arrive on Thursday."
voice: "coral"
```

**Steered read (gpt-4o-mini-tts):**
```text
input:        "Your order has shipped and will arrive on Thursday."
instructions: "Speak in a warm, upbeat customer-service tone; brisk but friendly pace."
voice:        "coral"
```
The `instructions` string is free-form natural language — describe tone, emotion, pacing, accent, character ("a weary film-noir detective narrating"). There are no fixed keywords.

## How-To (worked recipes)

### How to steer tone without polluting the spoken text
Problem: you want a cheerful read, not the word "cheerful" spoken.
```text
input:        "Today is a wonderful day to build something people love."
instructions: "Speak in a cheerful and positive tone."
```
Note: this only works on `gpt-4o-mini-tts`. On `tts-1`/`tts-1-hd` the field is ignored (not spoken, just ineffective).

### How to choose a voice character
Problem: wrong vocal identity.
```text
voice: "onyx"    ← deeper; try "nova"/"shimmer" (brighter), "sage"/"ballad", "echo"
```
Note: pick from the 13 presets via the `voice` option. Don't describe the voice in `input`.

### How to control pacing / a slow deliberate read
Problem: too fast for a tutorial.
```text
instructions: "Speak slowly and deliberately, pausing between steps."
speed:        0.9
```
Note: combine an `instructions` pacing cue with the numeric `speed` option (roughly 0.25–4.0; ~0.9 = slightly slow).

### How to output a specific audio format
Problem: you need WAV/opus, not MP3.
```text
OUTPUT PATH: line.wav   → response_format derived as "wav"
```
Note: media-tool sets `response_format` from the output file extension (mp3/wav/opus/aac/flac/pcm) — no separate option needed.

## Do's and Don'ts

### ✅ Do
- **Put spoken words in `input`, delivery in `instructions`.**
- **Use `gpt-4o-mini-tts`** when you want tone control.
- **Pick a `voice` preset** from the 13 supported names.
- **Use punctuation** for pauses and intonation.
- **Chunk long scripts** to stay under ~2000 input tokens.

### ❌ Don't
- **Don't write tone directions inside `input`** — they get spoken.
- **Don't expect `instructions` to work on `tts-1`/`tts-1-hd`** — it's silently ineffective there.
- **Don't invent voice names** — only the documented presets exist; an unknown name errors or falls back.
- **Don't paste markdown/URLs** — symbols get vocalized oddly.

## Negative Prompts / Exclusions

No negative-prompt concept — you supply exact speech. To avoid unwanted delivery, phrase `instructions` positively ("calm and even; no dramatic emphasis") and clean the `input`. media-tool sends no `negative_prompt` to this provider.

## Styling & Control

media-tool maps these `provider_options`:
- **`voice`** — preset name (default `alloy`). Supported: alloy, ash, ballad, coral, echo, fable, onyx, nova, sage, shimmer, verse, marin, cedar.
- **`instructions`** — natural-language delivery steer (**`gpt-4o-mini-tts` only**).
- **`speed`** — speaking rate float.
- **`language`** — language hint.
`response_format` is derived from the output extension, not an option.

## Aspect / Resolution / Duration Constraints

- **No aspect ratio** (audio); **no `duration_seconds`** control (length = however long the text is).
- **Input limit**: ~2000 tokens per request — chunk longer text.
- **Formats**: mp3, wav, opus, aac, flac, pcm (chosen by file extension).
- **No media-tool char cap** in `constraints()` (`None`) — but respect the token limit.

## Common Pitfalls & Troubleshooting

- **Tone directive spoken aloud** → you put it in `input`; move it to `instructions`.
- **`instructions` had no effect** → you're on `tts-1`/`tts-1-hd`; switch to `gpt-4o-mini-tts`.
- **Unknown voice error** → use one of the 13 documented presets.
- **Cut-off audio on long text** → exceeded ~2000 tokens; split into segments.
- **Odd pronunciation of symbols/numbers** → spell them out in `input`.
- **401/403** → check `OPENAI_API_KEY`.

## Integration Notes (media-tool specific)

- **`service: openai-tts`**, provider in `src/providers/openai_tts.rs`. Endpoint `https://api.openai.com/v1/audio/speech`, `Authorization: Bearer`.
- **API key**: env **`OPENAI_API_KEY`** (see `api_key_env` in `mod.rs`).
- **Default model** `gpt-4o-mini-tts`; **default voice** `alloy`.
- **`provider_options` keys read**: `voice`, `instructions` (mini-tts only), `speed`, `language`. `response_format` from the output file extension. `negative_prompt`, `duration_seconds`, attachments are **not** used.
- **Char limit**: none in `constraints()` (`None`); honor OpenAI's ~2000-token input limit.
- **Prep guidance**: emit **verbatim `input`**; when a specific tone/character is wanted, produce a concise `instructions` string and ensure the model is `gpt-4o-mini-tts`. Choose `voice` from the preset list.

## See Also
- `elevenlabs.md`, `qwen-tts.md` — sibling TTS providers (verbatim text; different steering — sliders vs `instructions`).
- `suno.md` / `udio.md` — music siblings (style briefs, not speech).
- `../use-case/media-processing.md` — voiceover/narration consumption (if present).
