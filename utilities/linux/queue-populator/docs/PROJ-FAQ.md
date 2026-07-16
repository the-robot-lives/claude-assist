# FAQ — queue-populator (Linux)

Anticipated why/when/compared-to-what questions. For procedures, see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for design rationale, see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use a voice memo tool that classifies with an LLM instead of just typing a note?

Because the classification step is the point — you say one unstructured
sentence and it lands as a correctly-typed JSONL entry in one of ~30 target
files (task vs. idea vs. reminder vs. raw log) without you deciding or
navigating there. The honest trade-off: it's slower than typing for a single
short note, and misclassification happens (fix via `systemPromptOverride`,
not by editing the compiled-in manifest — see
[howto/queue-files.md](howto/queue-files.md)). It pays off when you're
capturing many small thoughts hands-free — walking, cooking, mid-task — where
opening an editor and picking a file is the actual friction.

→ *See [PROJ-HOWTO.md#how-to-capture-a-voice-memo](PROJ-HOWTO.md#how-to-capture-a-voice-memo).*

### Why route my mic through virtual PipeWire devices instead of just switching each app's mic input?

Because switching device pickers per-app is the exact friction this avoids —
"robot open claude" flips routing by voice in under a second, no browser
settings dialog. The devices are also persistent and gated in-process (muted
= silence, not disconnected), so they stay visible in GNOME Settings even
when idle and never glitch on switch. Trade-off: it only helps if the
target app's mic input is *already* pinned once to `Claude`/`Codex`/`Llama` —
you still do that one-time setup per app.

→ *See [PROJ-HOWTO.md#how-to-let-claudecodexllama-hear-me-without-switching-mics](PROJ-HOWTO.md#how-to-let-claudecodexllama-hear-me-without-switching-mics).*

### Why on-device STT (sherpa-onnx) instead of a cloud speech API?

Because the wake-phrase listener runs continuously — every second of audio
would otherwise leave the machine, and cloud STT round-trip latency would
make the wake phrase feel laggy. On-device int8 zipformer keeps the always-on
loop private and fast; the trade-off is English-only, on-device accuracy
(not cloud-grade), and a one-time ~200MB model download. Only the final memo
*classification* step goes to an LLM API — see the Trust section below.

## Fit

### When is this the wrong tool for me?

If you're not on Ubuntu GNOME/PipeWire, or you work in a noisy/shared space
where an always-on wake-phrase listener and audible voice commands aren't
practical. It's also a poor fit if you just want a single dictation tool for
one app — this is a routing + classification system across a whole personal
task/note taxonomy, which is overhead you don't need for that.

### I already use OS-level dictation (e.g. GNOME's built-in Whisper). Do I still need this?

Dictation transcribes; it doesn't classify or route. queue-populator's value
is the LLM step that decides *which* of ~30 files a stray thought belongs in
and appends it there structured — dictation just types characters wherever
your cursor is. The two are complementary, not competing: nothing stops you
using both for different purposes.

### Does this help if I mostly work at a desk with a keyboard in reach?

Marginally. The voice-memo half is built for hands-busy or mid-task capture;
if your hands are already on a keyboard, typing directly into the target
queue file is faster than speaking, waiting for STT + LLM classification,
and reviewing. The mic-routing half (talking to Claude/Codex/Llama without
switching devices) still has value at a desk, independent of the memo
feature.

### Why would I pause listening instead of just quitting the app?

Because pause and quit stop different things. Pausing only silences the
wake-phrase/STT listener (the `Recording` target) — it doesn't touch
whichever assistant mic route is already open, so a live "Claude" routing
keeps carrying your voice while paused. Quitting kills the whole process,
including the PipeWire capture stream that feeds all four virtual sources,
so it silences everything at once — wake phrase, memo capture, *and* any
assistant currently listening. Pause if you want quiet from the memo/wake
side while mid-conversation with an assistant; quit only when you want that
routing to stop too.

→ *See [PROJ-HOWTO.md#how-to-pause-listening-or-quit-from-the-tray](PROJ-HOWTO.md#how-to-pause-listening-or-quit-from-the-tray).*

## Comparison

### How does this differ from the macOS `queue-populator`?

A different implementation end to end (Rust/PipeWire vs. Swift/CoreAudio)
behind the same config schema and queue format, so files interchange
between machines but expect Linux-specific rough edges.

→ *Full discussion: [faq/comparison.md](faq/comparison.md)*

### Why virtual mic devices instead of a browser extension or OS-level "mic sharing" feature?

Because it covers any app reading a PipeWire/PulseAudio source — native
apps and non-Chromium browsers included — not just browser tabs, with zero
per-site permissions.

→ *Full discussion: [faq/comparison.md](faq/comparison.md)*

### How is this different from just keeping four browser tabs open, one per assistant, each with mic already granted?

That works too and needs no PipeWire config, but it's browser-only and
still tab/window juggling; this tool is app-agnostic and switches by voice.

→ *Full discussion: [faq/comparison.md](faq/comparison.md)*

## Capability

### Can I use this without paying for an LLM API?

Yes — set `llm.provider` to `ollama` and point `baseUrl` at a local Ollama
instance; no API key is required or stored. Classification quality depends
entirely on the local model you run, which is typically weaker than
hosted frontier models at this task.

→ *See [howto/configure-llm-provider.md](howto/configure-llm-provider.md).*

### Can I tell it by voice which file a memo should go to?

No. The LLM picks the target file from memo content alone; there's no voice
override. If it's consistently wrong for a category, adjust
`systemPromptOverride` in `config.json` rather than expecting a "file it
under X" command — that hook doesn't exist.

→ *See [howto/queue-files.md](howto/queue-files.md).*

### Can I route my mic to two assistants (e.g. Claude and Codex) at the same time?

No — opening one assistant target always mutes the others by design; the
four virtual sources share a single physical mic feed, and the router
enforces exclusivity so only one is ever "live," which also stops you from
accidentally talking into an app you didn't mean to route into. There's no
config flag to relax this. If you need genuinely simultaneous multi-app
dictation, this tool won't do it — you'd need separate physical input
devices instead.

→ *See [PROJ-HOWTO.md#how-to-let-claudecodexllama-hear-me-without-switching-mics](PROJ-HOWTO.md#how-to-let-claudecodexllama-hear-me-without-switching-mics).*

### Does queue-populator work fully offline?

Wake-phrase detection, recording, and transcription do (on-device STT). Memo
*classification* does not — it's an HTTP call to whichever LLM provider you
configured, `ollama` (local) excepted. Offline, memos will sit in
`Processing` until the request fails or a network path is restored.

## Caveats

### What does an always-on wake-phrase listener cost me in resources/privacy?

It runs continuous STT inference on your default input device the whole time
the app is running — a background CPU cost, not zero. Privacy-wise, audio
never leaves the machine for the listening/transcription step (on-device
STT); only the classified memo *text* is sent to your configured LLM
provider once you say "that is all". Pausing from the tray (see
[PROJ-HOWTO.md#how-to-pause-listening-or-quit-from-the-tray](PROJ-HOWTO.md#how-to-pause-listening-or-quit-from-the-tray))
stops the always-on inference without quitting.

### What does each memo classification cost in LLM API spend?

One short chat-completion call per approved memo — cheap per call on any of
the supported providers, but it's metered API spend, not free, unless you
choose `ollama`. There's no local cap or budget guard built in; cost scales
with memo volume and the model you pick in
[howto/configure-llm-provider.md](howto/configure-llm-provider.md).

### Are my voice recordings kept anywhere?

The live mic audio is processed in memory for STT and virtual-mic routing
and is not written to disk by default. If `ffmpeg` is installed, the spoken
memo audio *is* additionally exported to an MP3 alongside the JSONL entry
(see queue file catalog) — remove `ffmpeg` or delete those exports if you
don't want a recorded copy to persist.

→ *See [howto/manage-memo-recordings.md](howto/manage-memo-recordings.md).*

### What happens if the fuzzy wake/command phrase misfires?

False positives are possible with short, common phrases — it's matched
fuzzily against a continuous live transcript, not push-to-talk. Pick
distinct 2-3+ word phrases (default "hey robot" already is) and see
[howto/customize-phrases.md](howto/customize-phrases.md) if false triggers
are frequent in your environment.

## Trust

### Is my LLM API key stored in plaintext?

No — any plaintext key you save into `config.json` is transparently
encrypted on save (`🔒:v1:` prefix) by shelling out to the monorepo's `dc`
tool, and an alias is shown in the UI instead of the key. The honest caveat:
this requires `dc` installed at `~/.local/bin/dc`; if it's missing, saving a
plaintext key fails outright rather than silently storing it unencrypted —
use an `env:VAR_NAME` reference instead if you don't want to install `dc`.

→ *See [howto/configure-llm-provider.md](howto/configure-llm-provider.md).*

### What does the configured LLM provider actually see?

Only the transcribed memo text (plus a system prompt describing the queue
taxonomy) at classification time — not raw audio, not your full queue
history, not other memos. Which provider that is, and therefore whose
infrastructure sees that text, is entirely your `llm.provider` choice,
including a fully local option (`ollama`).

### Does uninstalling remove my memo history and config?

No, and this is deliberate, not an oversight: `./uninstall.sh` removes the
binary, autostart entry, and PipeWire config, but leaves
`~/.config/queue-populator` (including your encrypted API key) and the
downloaded STT models under `~/.local/share/queue-populator/models`
untouched. Your queue files under `~/personal-development/queue/` are never
touched by install or uninstall. Delete these by hand for a fully clean
removal.

→ *See [PROJ-HOWTO.md#how-to-uninstall-queue-populator](PROJ-HOWTO.md#how-to-uninstall-queue-populator).*
