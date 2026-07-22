# Project Layout — queue-populator (Linux)

Voice-driven queue populator for Ubuntu GNOME / PipeWire — Rust port of
`utilities/osx/queue-populator`. Listens for a wake phrase, records a spoken
memo, classifies it with an LLM, appends JSONL entries to queue files, and
routes the live mic into virtual PipeWire mic devices on voice command.

```
queue-populator/
├── src/                            # Rust source (lib + bin) → [layout/src.md](layout/src.md)
│   ├── audio/                      #   PipeWire capture + virtual mic fan-out
│   ├── config/                     #   Config store, LLM providers, secrets (dc)
│   ├── llm/                        #   LLM client, prompts, response parsing
│   ├── queue/                      #   JSONL queue entries, manifest, writer
│   ├── stt/                        #   sherpa-onnx speech-to-text engine + models
│   ├── ui/                         #   egui windows, ksni tray, sound cues
│   ├── coordinator.rs              #   Central event loop / side-effect executor
│   ├── state_machine.rs            #   Pure state transitions (no IO)
│   ├── phrase_detector.rs          #   Wake/command phrase matching (fuzzy)
│   ├── lib.rs                      #   Crate root — platform-neutral core
│   └── main.rs                     #   Binary entry point — wires all layers
├── config/                         # Installed system config
│   └── 10-robot-virtual-mics.conf  #   PipeWire virtual sources (Recording/Claude/Codex/Llama)
├── docs/                           # Project documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Tree-only companion (keep in sync)
│   └── layout/                     #   Detailed per-directory breakdowns
├── Cargo.toml                      # Crate manifest — deps: pipewire, sherpa-onnx, eframe, ksni
├── Cargo.lock                      # Locked dependency versions (committed)
├── Makefile                        # compile/test/install/clean (Linux-gated)
├── install.sh                      # Build + install binary, pipewire config, STT models, autostart
├── uninstall.sh                    # Remove binary/autostart/pipewire config (keeps config+models)
├── .gitignore                      # Ignores target/
└── README.md                       # Start here — voice commands, stack, build & verify
```

Note: `target/` (cargo build output) is gitignored and not documented.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `~/.config/queue-populator/config.json` | LLM provider config (shared schema with macOS app); API keys encrypted via repo `dc` tool |
| `config/10-robot-virtual-mics.conf` | Installed by `install.sh` to `~/.config/pipewire/pipewire.conf.d/` |
| STT models | Downloaded by `install.sh` to `~/.local/share/queue-populator/models` (override: `QP_MODEL_DIR`) |

## Build

Linux-only (PipeWire). Ubuntu build deps: `libpipewire-0.3-dev pkg-config clang libclang-dev`.
Runtime helpers: `ffmpeg` (memo MP3 export), `pipewire-utils` (`pw-play`/`pw-cli`).
Run `./install.sh`, verify with `queue-populator --check`.
