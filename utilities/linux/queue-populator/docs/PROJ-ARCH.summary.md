# Architecture Summary — queue-populator (Linux)

## Overview

Voice-driven Ubuntu GNOME / PipeWire desktop utility (Rust port of
`utilities/osx/queue-populator`): wake-phrase memo capture, on-device
sherpa-onnx STT, LLM classification into JSONL queue entries under
`~/personal-development/queue/`, plus voice-controlled routing of the live mic
into four persistent PipeWire virtual sources (Recording/Claude/Codex/Llama).
Event-driven multi-threaded pipeline over crossbeam channels; platform-neutral
core in lib.rs, PipeWire/sherpa-onnx/ksni/egui layers wired in main.rs.

## Core Components

- `src/audio/` — PipeWire capture + in-process fan-out to STT and gated virtual sources (lock-free atomics, assistants exclusive)
- `src/stt/` — sherpa-onnx streaming zipformer engine + model management
- `src/coordinator.rs` — central event loop; sole side-effect executor
- `src/state_machine.rs` — pure transitions: Idle → Recording → MemoReview → Processing → Review/Revising
- `src/phrase_detector.rs` — fuzzy wake/command phrase matching
- `src/llm/` — provider-agnostic LLM client (ureq), prompts, response parsing
- `src/queue/` — JSONL entry schema, manifest, append-only writer
- `src/config/` — config store (schema shared with macOS app), `dc`-backed secret store
- `src/ui/` — ksni tray, egui windows, notifications, sound cues
- `config/10-robot-virtual-mics.conf` — pipewire.conf.d drop-in for the virtual sources
- `install.sh`/`uninstall.sh` — binary, PipeWire config, STT models, autostart

## Key Decisions

- Pure state machine + coordinator executor (mirrors macOS design; testable without IO)
- Persistent, gated virtual sources — no relinking, muted = silence, no glitches
- On-device STT; only memo classification calls an LLM API
- API keys encrypted via monorepo `dc` tool (🔒:v1: prefix)
- config.json schema shared with the macOS port

## Ecosystem Fit

Compiled Rust desktop app — no `share/k8-lib`, `.infra-config.yaml`, or
docker/helm pipeline. Installs binary to `~/.local/bin`; Makefile gates
compile/test/install on Linux so monorepo builds skip elsewhere. Runtime deps:
PipeWire ≥0.3, pipewire-utils, ffmpeg, repo `dc`. Verify: `queue-populator --check`.
