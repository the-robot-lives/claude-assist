# queue-populator — FAQ

Why/when/compared-to-what questions. For *what it is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *how to do things*, see [PROJ-HOWTO.md](PROJ-HOWTO.md).

## Motivation

### Why would I speak a memo through an LLM classifier instead of just typing it into the right file myself?
Because the classifier is what lets one wake phrase target ~30 different queue files without you remembering which file is which. `QueueManifest` feeds file-path + description pairs into the LLM prompt, so "remind me to check the deploy tomorrow" and "add spaced-repetition cards for Elixir GenServers" both land correctly without you knowing the manifest exists. The honest trade-off: classification can be wrong, which is why nothing is written until you approve it in the review step — you're trading typing for a review click/phrase, not for zero attention.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-capture-and-approve-a-voice-memo-the-everyday-workflow) for the approve/revise loop.*

### Why is there a human approve/revise step instead of writing the LLM's output directly?
Because LLM classification is probabilistic and the queue files are meant to be trustworthy inputs to downstream personal-development tooling — a silently misfiled entry is worse than a few seconds of review. You can approve, revise with a spoken correction, or cancel outright at any point before the write. This is a deliberate design decision (see [PROJ-ARCH.md § Key Decisions](PROJ-ARCH.md#key-decisions)), not a missing feature — there is no "trust mode" that skips review.

### Why does queue-populator launch manually instead of starting automatically at login?
Because that autostart behavior was deliberately removed: `install.sh` actively hunts down and deletes any previously-installed `com.noizu.queue-populator.plist` LaunchAgent (`launchctl bootout`/`unload` + `rm`) rather than installing one, and prints "app is now launched manually" as confirmation. The trade-off is convenience for control — an app that's always listening for wake phrases shouldn't silently reappear after every reboot without you choosing that; you re-launch it (double-click, or `open`) each session instead. If you want login autostart back, you'd need to add your own LaunchAgent plist — the project doesn't currently ship one.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-install-and-verify-it-for-the-first-time).*

### Why route audio through virtual mic devices instead of just using the system default mic in Claude/Codex/etc.?
Because those apps then can't tell whose voice they're hearing, and you can't route to one assistant at a time without unplugging your real mic from everything else. The virtual devices (`Recording`, `Claude`, `Codex`, `Llama`) let queue-populator keep listening for its own wake phrases on `Recording` while independently opening/closing which assistant hears you, via voice command, with exclusive routing so only one assistant carries audio at once.
→ *See [howto/virtual-microphones.md](howto/virtual-microphones.md).*

## Fit

### Is this the right tool if I just want a quick CLI note-taker?
Not yet as shipped. The README describes a broader "channels" vision (CLI `q "..."`, SMS/bot/email) that motivated the project, but the implementation that actually exists is the voice channel plus virtual-mic routing — no `q` binary, no SMS/email intake. If you want CLI-only capture today, this is the wrong tool; if voice-triggered capture with LLM routing is what you want, it's a good fit.

### Is this the right tool if I'm not on macOS?
No. It's a Swift/AppKit menu bar app using Apple's Speech framework and a CoreAudio HAL driver — both macOS-only. A separate Linux port using PipeWire for virtual-mic routing exists elsewhere in the monorepo, but it is a different codebase, not this one running under compatibility layers.

### Is this the right tool if I need multi-user or networked queue access?
No. It's an explicitly single-user, local-filesystem tool — JSONL files under `~/personal-development/queue/` with no database, no locking, no network service. If you need shared/concurrent access to the queue data, you'd be building that downstream yourself; this project doesn't provide it.

## Comparison

### How does this differ from just using macOS Dictation or Siri Shortcuts?
Dictation/Shortcuts transcribe or trigger canned actions; they don't classify free-form speech into one of ~30 structured destination files with multi-entry splitting. queue-populator's value is the LLM classification + review step in between transcription and the write — Dictation stops at transcription, Shortcuts stops at pattern-matched triggers.

### How does the virtual-mic feature differ from BlackHole or Loopback used directly?
It *is* BlackHole under the hood — `Driver/build-virtual-mics.sh` builds four rebranded, ad-hoc-signed copies of BlackHole (MIT-licensed), one per device name. The difference is app-level control: queue-populator decides which of `Claude`/`Codex`/`Llama` is actively fed your mic (via voice command, exclusive routing) rather than you manually toggling audio routing in a separate utility. See [Driver/README.md](../Driver/README.md) for the full rationale on why BlackHole was rebranded rather than hand-written.

## Capability

### Can I add a new destination queue file without rebuilding the app?
No — `QueueManifest` is compiled into the binary, not a runtime config file. Editing it requires a source change and `./install.sh` rebuild. A plain app restart will not pick up a new category.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-queue-category).*

### Can multiple LLM providers be used, or is it locked to Anthropic?
Multiple providers are supported: anthropic (default), openai, groq, cerebras, deepseek, zai, litellm, ollama, and a generic custom endpoint. Provider/model/base-URL/API-key resolve through `LlmConfig` with env-var fallbacks per provider, so switching providers doesn't require touching code.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-configure-the-llm-provider-and-api-key).*

### Can I run recognition fully on-device, with no network calls at all?
Speech-to-text can run on-device (the transcript step never has to leave your Mac), but the classification step is an LLM call — unless you point the LLM provider at a local model server (Ollama or a local LiteLLM/custom endpoint), that step does go over the network. There's no fully-offline mode using a cloud LLM provider.

## Caveats

### What happens if I say a short/common trigger word by accident?
False triggers are a real, known limitation — phrases are matched against live speech-recognition output, so a short/common wake or approve phrase (e.g. "yes") will misfire on normal conversation. The defaults use distinct 2-3 word phrases for this reason; if you customize them, keep them multi-word and uncommon.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-change-waketrigger-phrases-or-the-queue-base-path).*

### What's the risk in installing the virtual-mic HAL driver?
It restarts `coreaudiod` (`sudo killall -9 coreaudiod`) as part of install, which will briefly interrupt any audio in progress system-wide, and a broken HAL driver can in principle wedge the audio subsystem. This is the exact risk the project avoided by rebranding proven BlackHole binaries instead of shipping ~1k lines of untested bespoke CoreAudio plug-in C — but installing *any* HAL driver still touches a system-level surface, so don't install it on a machine mid-recording/mid-call.
→ *See [Driver/README.md](../Driver/README.md).*

### What happens to my queue data and config on uninstall?
`uninstall.sh` removes the app, launch agent, and old binaries only — it deliberately leaves `~/.config/queue-populator/` (config + debug log) and `~/personal-development/queue/` (your captured data) intact. If you want a full wipe, delete those directories yourself afterward.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-uninstall).*

### Does the memo audio get kept, and in what format?
Audio export prefers real MP3 (via `lame`, CAF→WAV→MP3), falls back to AAC `.m4a` via `afconvert` if `lame` isn't available, and as a last resort keeps the raw `.caf` capture — so the retained format depends on what's installed on your Mac, not a fixed choice. This was itself a past bug: `afconvert` cannot encode MP3 on macOS, so early builds silently failed to export any audio at all (fixed in `m4-audio-reliability-fixes`).

## Trust

### Are my LLM API keys stored in plain text?
No — keys resolve via `SecretStore` with env-var fallbacks per provider rather than being required in a plain config file. Exactly how "secret" that storage is depends on `SecretStore`'s backing mechanism; if you need guarantees beyond "not in the plain JSON config," check `Sources/Config/` directly before trusting it with a high-value key.

### Does any of my voice/memo content leave my Mac?
The LLM classification step does, by design — your memo text (not raw audio) is sent to whichever LLM provider you've configured, unless that provider is a local model server (Ollama/local LiteLLM/custom). Speech-to-text transcription itself can be on-device. Nothing is written to your queue files, and nothing is sent anywhere at all, until you review and approve the memo.
