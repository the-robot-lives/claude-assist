# Project Architecture

## Overview

Queue-populator is a macOS menu bar application (Swift 6, SwiftPM, AppKit) that turns spoken input into structured personal-queue entries. It listens continuously for a wake phrase, transcribes speech via Apple's Speech framework, sends the finished memo to an LLM for classification, and — after a review/approve step — appends JSONL entries to the appropriate queue file under `~/personal-development/queue/` (routing manifest of ~30 files: tasks, reminders, ideas/{category}, study, etc.).

A second, independent feature routes the live microphone into four virtual mic devices (`Recording`, `Claude`, `Codex`, `Llama`) provided by a rebranded BlackHole CoreAudio HAL driver, controlled by voice commands (`robot open claude`, ...). Assistant routing is exclusive: opening one assistant device mutes the others; `Recording` is always fed while listening.

## System Diagram

```mermaid
graph TB
    Mic[Microphone] --> SE[SpeechEngine<br/>Speech.framework]
    SE -->|audio buffers| VMR[VirtualMicRouter]
    SE -->|audio buffers| MAR[MemoAudioRecorder]
    VMR --> HAL["Virtual mic devices<br/>(BlackHole-based HAL driver)"]
    SE -->|transcript| PD[PhraseDetector]
    PD -->|AppEvent| SM[AppStateMachine]
    SM --> C[Coordinator]
    C --> LLM["LlmClient<br/>(anthropic/openai/groq/ollama/...)"]
    LLM -->|ProposedEntry[]| RW[ReviewWindow]
    RW -->|approve| QW[QueueWriter]
    QW --> Q[("~/personal-development/queue/*.jsonl")]
    C --- UI["StatusBarController / TranscriptWindow / StateOverlay"]
```

## Core Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `main.swift` / `AppDelegate` | `Sources/` | App bootstrap, `--authorize` permission mode, config load, starts Coordinator |
| `Coordinator` | `Sources/Coordinator.swift` | Central wiring: owns speech engine, state machine, LLM client, windows, mic router |
| `SpeechEngine` | `Sources/Audio/` | Continuous mic capture + on-device/server speech recognition; emits transcripts and raw audio buffers |
| `PhraseDetector` | `Sources/Recognition/` | Matches configurable trigger phrases (wake/end/cancel/approve/revise, mic open/close) |
| `AppStateMachine` | `Sources/StateMachine/` | States: idle → recording → memoReview → processing → review/revising; drives UI hints |
| `LlmClient` / `PromptBuilder` | `Sources/LLM/` | Classifies memo text into `ProposedEntry[]` against the queue manifest; multi-provider HTTP client |
| `QueueManifest` / `QueueWriter` | `Sources/Queue/` | Declarative list of ~30 target `.jsonl` files with descriptions (fed to the LLM prompt); append-only writer |
| `VirtualMicRouter` / `MicTarget` | `Sources/Audio/` | Thread-safe fan-out of live mic buffers into virtual mic devices; exclusive assistant routing |
| Config layer | `Sources/Config/` | `QueuePopulatorConfig` persistence, LLM provider/model/base-URL/env-key resolution, secret storage |
| UI layer | `Sources/UI/` | Menu bar item, live transcript window with inline config, review/memo-review windows, state overlay |
| HAL driver | `Driver/` | `build-virtual-mics.sh` builds four rebranded BlackHole loopback devices into `/Library/Audio/Plug-Ins/HAL/` |

## Data Flow (memo pipeline)

1. Idle: SpeechEngine streams transcription; PhraseDetector watches for the wake phrase.
2. Recording: transcript chunks accumulate until the end phrase (or cancel).
3. Memo review: user edits or says the approve-memo phrase.
4. Processing: `LlmClient` classifies the memo into one or more `ProposedEntry` records (target file + text), using `QueueManifest` descriptions in the prompt.
5. Review: entries shown; approve writes them via `QueueWriter`, revise loops back with spoken corrections.
6. Entries land as append-only JSONL (`ts`, `type`, `text`, `source`, `processed: false`).

Mic-routing voice commands (`micOpen`/`micClose` events) bypass the memo state machine and are handled directly by the Coordinator.

## Configuration & Secrets

Runtime config (phrases, locale, on-device recognition, input device, queue base path, LLM provider/model) is edited via the config dialog or the transcript window's inline editor and persisted by `ConfigStore`. LLM API keys resolve via `SecretStore` with env-var fallbacks per provider (`LlmConfig.envVarKeys`/`envVarFallbacks`). Supported providers: anthropic (default), openai, groq, cerebras, deepseek, zai, litellm, ollama, custom.

## Deployment

`install.sh` builds with SwiftPM, assembles `/Applications/Queue Populator.app` (binary, icns, Info.plist), and installs a launchd LaunchAgent (`com.noizu.queue-populator.plist`, `RunAtLoad`, logs to `/tmp/queue-populator.{out,err}.log`) for login autostart. `uninstall.sh` reverses it. The HAL driver is a separate one-time install (`Driver/build-virtual-mics.sh`, requires Xcode; restarts `coreaudiod`). Entitlements cover mic + speech recognition; first run (or `--authorize`) prompts for permissions.

## Place in the Noizu Utilities Ecosystem

Unlike the shell utilities under `utilities/`, queue-populator does **not** use `share/k8-lib`, `.infra-config.yaml`, or the `~/.local/bin` symlink install — it is a self-contained macOS app with its own `install.sh`. Its `Makefile` guards every target on `uname -s == Darwin`, so monorepo-wide builds (`make install-utilities` and friends) skip it cleanly on Linux hosts. The queue files it feeds are consumed by downstream personal-development tooling outside this project. A separate Linux port (PipeWire-based virtual mic routing) exists elsewhere in the monorepo; this is the macOS original.

## Key Decisions

- **JSONL + filesystem, no DB**: append-only, human-readable, single-user local tool — no concurrency or migration overhead.
- **LLM classification over heuristics**: memo text is free-form; the manifest-driven prompt lets one classifier target ~30 queue files and split a memo into multiple entries.
- **Human-in-the-loop review**: LLM output is never written without an approve step (spoken or clicked), with a revise loop for corrections.
- **Rebranded BlackHole for virtual mics**: a proven MIT-licensed HAL loopback driver, customized four ways at build time, instead of ~1k lines of untestable bespoke CoreAudio plug-in C (a faulty HAL driver can wedge `coreaudiod` system-wide). See `Driver/README.md`.
- **Exclusive assistant routing**: only one of Claude/Codex/Llama carries audio at a time, preventing accidental multi-assistant capture.

## Status

Implemented and installable (~4.5k lines of Swift). The README's channel list (CLI `q` command, SMS/bot/email) describes the original broader concept; the shipped implementation is the voice channel plus virtual mic routing.
