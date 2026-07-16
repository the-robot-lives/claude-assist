# Changelog — utilities/linux/queue-populator

## [Unreleased]
- [Accumulating changes since the last milestone tag]

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
