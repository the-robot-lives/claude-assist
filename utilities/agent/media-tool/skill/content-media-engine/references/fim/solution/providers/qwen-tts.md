# Qwen-TTS / CosyVoice — verbatim multilingual speech via Alibaba DashScope

Qwen-TTS (Alibaba's Qwen team, CosyVoice lineage) reads text aloud in a chosen preset voice, served through **DashScope / Alibaba Cloud Model Studio**. Like all TTS, the prompt is the **verbatim words to be spoken** — voice, language, and delivery are set by options, not described in the text. Its strengths are **low latency (Flash)**, strong **Chinese + multilingual/dialect** coverage, and a good cost/quality point. In media-tool this is the low-latency voice provider, wired as `service: qwen-tts`.

**Current model**: `qwen3-tts-flash` (stable alias; web-verified equivalent to `qwen3-tts-flash-2025-11-27`) — the current fast, expressive, streaming-capable model. The CosyVoice family (`cosyvoice-v3.5-plus`, `cosyvoice-v3.5-flash`, `cosyvoice-v3-flash`) is the related higher-fidelity/voice-cloning lineage on the same platform. **Access**: paid API (DashScope).
**Wired in media-tool as**: `service: qwen-tts` (see `src/providers/qwen_tts.rs`), default model `qwen3-tts-flash`, default voice `Cherry`.

> Version note (web-verified 2026-07): Qwen3-TTS covers ~10 major languages (Chinese, English, Japanese, Korean, German, French, Russian, Portuguese, Spanish, Italian) plus dialectal profiles. Preset voices include **Cherry, Ethan, Nofish, Jennifer, Ryan, Katerina, Elias, Jada, Dylan, Sunny, Li, Marcus, Roy, Peter, Rocky, Kiki, Eric**. Sources: [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS), [DashScope non-real-time TTS docs](https://www.alibabacloud.com/help/en/model-studio/qwen-tts), [Model Studio TTS models](https://help.aliyun.com/en/model-studio/tts-model/).

## How This Model Reads Prompts

The prompt (`text`) is **literal speech**, read verbatim. Delivery is controlled by:

1. **`voice`** — a named preset (Cherry default) that fixes the speaker identity.
2. **`language_type`** — which language/dialect to speak (default "English"). Qwen-TTS is multilingual and can auto-detect, but pinning it avoids mispronunciation on ambiguous text.
3. **`instructions`** (optional) — a delivery steer, when supported by the model variant.

- **Don't describe the voice in the text** — it will be spoken.
- **Punctuation drives prosody** — commas/periods for pauses, native punctuation for CJK.
- **Length**: write the exact passage; keep requests to reasonable single utterances and chunk long scripts.

## Prompt Grammar / Syntax

No in-text markup grammar. Control is the `text` / `voice` / `language_type` / optional `instructions` split.

**Basic:**
```text
text:          "Welcome — your appointment is confirmed for Thursday at ten."
voice:         "Cherry"
language_type: "English"
```

**Chinese / dialect:**
```text
text:          "欢迎光临，您的预约已确认。"
voice:         "Dylan"
language_type: "Chinese"
```

**Optional delivery steer (variant-dependent):**
```text
instructions: "Speak gently and reassuringly, at a measured pace."
```
> Uncertain: SSML/prosody-tag support varies across the CosyVoice/Qwen-TTS variants and is **not confirmed** for the wired `qwen3-tts-flash` path. Do NOT emit `<speak>`/`<prosody>` SSML unless a specific variant is verified to accept it — on a non-SSML model the tags get read aloud. Prefer the `instructions` field and punctuation for delivery control.

## How-To (worked recipes)

### How to speak in a chosen preset voice
Problem: you need a specific speaker.
```text
text:  "Thanks for calling. How can I help you today?"
voice: "Jennifer"     ← pick from the preset list (Cherry/Ethan/Ryan/Katerina/...)
```
Note: identity is the `voice` preset; never a description in `text`. Only use documented preset names.

### How to produce non-English or dialectal speech
Problem: multilingual output or a dialect.
```text
text:          "Bonjour, votre commande est prête."
voice:         "Katerina"
language_type: "French"
```
Note: set `language_type` explicitly for reliable pronunciation; Qwen3-TTS covers ~10 languages plus dialect profiles.

### How to steer delivery / tone
Problem: it sounds flat.
```text
instructions: "Warm, friendly, slightly upbeat; natural conversational pace."
```
Note: use the `instructions` option where the variant supports it. If tone doesn't change, the variant likely ignores it — fall back to voice choice + punctuation.

### How to route to the correct DashScope region
Problem: latency or account region (CN vs international).
```text
OPTION: region = "intl"   (default; dashscope-intl endpoint)
        region = "cn"     (mainland dashscope endpoint)
```
Note: media-tool switches endpoint by `region`; "intl" is the default. Use "cn" only for a mainland-China DashScope account.

## Do's and Don'ts

### ✅ Do
- **Put verbatim words in `text`**, nothing else.
- **Pick `voice` from the documented preset list.**
- **Set `language_type`** for non-English or ambiguous text.
- **Use punctuation** (including native CJK punctuation) for prosody.
- **Match `region`** to your DashScope account.

### ❌ Don't
- **Don't describe the voice in `text`** — spoken literally.
- **Don't emit SSML** unless you've confirmed the variant accepts it — otherwise tags are vocalized.
- **Don't invent voice names** — unknown presets error or fall back.
- **Don't assume `instructions` always applies** — support is variant-dependent; verify.
- **Don't send one giant script** — chunk long passages.

## Negative Prompts / Exclusions

No negative-prompt concept for TTS — you provide exact speech. Avoid unwanted output by cleaning `text` and choosing an appropriate `voice`/`language_type`. media-tool sends no `negative_prompt` to this provider.

## Styling & Control

media-tool maps these `provider_options`:
- **`voice`** — preset speaker (default `Cherry`).
- **`language_type`** — language/dialect (default `English`; passed as the API `language_type`).
- **`instructions`** — delivery steer where supported.
- **`region`** — `intl` (default) or `cn`, selecting the DashScope endpoint.
No numeric stability/similarity sliders are wired for this provider (unlike ElevenLabs). Do not invent them.

## Aspect / Resolution / Duration Constraints

- **No aspect ratio** (audio); **no `duration_seconds`** control.
- **Output**: DashScope returns an audio URL that media-tool downloads to the output path; the returned format is whatever the model produces (commonly WAV/MP3). There is no extension-driven `response_format` negotiation like OpenAI/ElevenLabs.
- **No media-tool char cap** in `constraints()` (`None`) — keep to reasonable single utterances; chunk long text.

## Common Pitfalls & Troubleshooting

- **Voice description spoken aloud** → move it out of `text`; use `voice`/`instructions`.
- **SSML tags read literally** → the variant doesn't support SSML; remove tags, use punctuation + `instructions`.
- **Wrong language/pronunciation** → set `language_type` explicitly.
- **Unknown voice** → use a documented preset (Cherry, Ethan, Ryan, ...).
- **Region/endpoint errors** → set `region` to match your account (`intl` vs `cn`).
- **No audio URL in response** → the request failed upstream; check model name + `DASHSCOPE_API_KEY`.
- **401/403** → check `DASHSCOPE_API_KEY`.

## Integration Notes (media-tool specific)

- **`service: qwen-tts`**, provider in `src/providers/qwen_tts.rs`. Endpoint is DashScope multimodal generation: `https://dashscope-intl.aliyuncs.com/...` (intl) or `https://dashscope.aliyuncs.com/...` (cn), `Authorization: Bearer`. Response returns an audio URL that is then downloaded.
- **API key**: env **`DASHSCOPE_API_KEY`** (see `api_key_env` in `mod.rs`).
- **Default model** `qwen3-tts-flash`; **default voice** `Cherry`; **default language** `English`; **default region** `intl`.
- **`provider_options` keys read**: `voice`, `language` (→ `language_type`), `instructions`, `region`. `negative_prompt`, `duration_seconds`, attachments are **not** used.
- **Char limit**: none in `constraints()` (`None`).
- **Prep guidance**: emit **verbatim `text`**; set `voice` from the preset list and `language_type` to match the content. Use `instructions` for tone only if the variant supports it; never emit SSML unless verified.

## See Also
- `elevenlabs.md`, `openai-tts.md` — sibling TTS providers (verbatim text; ElevenLabs uses sliders, OpenAI uses `instructions`, Qwen uses preset+language).
- `suno.md` / `udio.md` — music siblings (style briefs, not speech).
- `../use-case/media-processing.md` — narration/voiceover consumption (if present).
