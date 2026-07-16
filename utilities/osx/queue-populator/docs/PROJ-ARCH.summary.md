# Project Architecture — Summary

macOS menu bar app (Swift 6 / AppKit / SwiftPM) that captures wake-phrase-triggered voice memos, transcribes them with Apple Speech, classifies them via an LLM against a ~30-file queue manifest, and — after user review/approve — appends JSONL entries to `~/personal-development/queue/`. Also routes live mic audio into virtual microphone devices (Recording / Claude / Codex / Llama) backed by a rebranded BlackHole CoreAudio HAL driver, with exclusive assistant routing via voice commands.

- **Pipeline**: SpeechEngine → PhraseDetector → AppStateMachine (idle/recording/memoReview/processing/review/revising) → LlmClient → ReviewWindow → QueueWriter
- **LLM providers**: anthropic (default), openai, groq, cerebras, deepseek, zai, litellm, ollama, custom; keys via SecretStore + env fallbacks
- **Persistence**: append-only JSONL on local filesystem, no database
- **Virtual mics**: Driver/build-virtual-mics.sh installs 4 BlackHole-derived HAL loopback devices; app fans mic buffers into open targets
- **Deploy**: install.sh → /Applications/Queue Populator.app + launchd LaunchAgent (login autostart); Makefile no-ops on non-Darwin
- **Ecosystem**: self-contained — does not use k8-lib, .infra-config.yaml, or ~/.local/bin install; separate PipeWire-based Linux port exists
- **Status**: implemented (~4.5k lines Swift); voice channel shipped, README's CLI/SMS channels remain conceptual
