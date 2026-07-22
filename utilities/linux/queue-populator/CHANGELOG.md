# Changelog — utilities/linux/queue-populator

## [Unreleased]

### Fixed
- Keep queue-write completion/errors as the final visible status and return the UI/state machine to idle after failures.
- Prevent repeated virtual-mic commands from one growing speech-recognition partial.
- Respect PipeWire capture chunk offsets and bounds instead of decoding stale buffer prefixes.
- Make phrase removal safe when Unicode lowercasing changes UTF-8 byte lengths.
- Prevalidate queue batches so an invalid later path cannot leave earlier entries partially written.
- Preserve memo audio as a visible WAV when MP3 conversion fails and avoid overwriting same-second recordings.
- Treat `--help` as a successful command, make `--verbose` emit partial STT diagnostics, normalize LLM config whitespace, validate required credentials/base URLs before network calls, and normalize model-list endpoints.
- Eliminate UTF-8 API-key prefix panics, recover poisoned worker locks, replace fallible startup/FFI unwraps, enforce recording duration/memory limits, and make tray Quit close the GUI event loop.

### Added
- Regression/unit coverage for write state and ordering, repeated mic commands, PipeWire buffer decoding, Unicode phrases, queue batch validation, memo preservation/naming, CLI parsing, and LLM/model URL validation.

## [m2-arch-docs] — 2026-07-16 — tag: `utilities-linux-queue-populator/m2-arch-docs`
Milestone summary: added standard PROJ-ARCH/PROJ-LAYOUT documentation set describing the tool's architecture and source layout.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — architecture overview
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — directory/layout reference
- `docs/layout/src.md` — `src/` module-by-module breakdown

## [m1-initial-rust-port] — 2026-07-07 — tag: `utilities-linux-queue-populator/m1-initial-rust-port`
Milestone summary: initial Rust port of the macOS `queue-populator` tool for Ubuntu GNOME/PipeWire — wake-phrase-triggered voice memo capture, LLM classification into queue JSONL, and voice-controlled virtual mic routing (Claude/Codex/Llama).

### Added
- Streaming STT via sherpa-onnx (on-device, int8 zipformer) with endpoint detection
- PipeWire audio capture fanned out to STT + four virtual mic sinks (`Recording`, `Claude`, `Codex`, `Llama`), config in `config/10-robot-virtual-mics.conf`
- Wake-phrase state machine (`hey robot` / `that is all` / approve / revise / cancel / open-close-mic commands)
- LLM classification pipeline (config-compatible with macOS app, `~/.config/queue-populator/config.json`, `dc`-encrypted API keys)
- Queue writer producing structured JSONL entries under `~/personal-development/queue/`
- ksni tray UI + egui transcript/config/review windows + desktop notifications
- `install.sh` / `uninstall.sh` for binary, pipewire config, models, and autostart; `queue-populator --check` verification command
