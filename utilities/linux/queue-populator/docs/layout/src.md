# src/ — Rust Source

Crate root (`lib.rs`) holds platform-neutral core; audio/STT/UI layers sit on
top. Most modules are direct ports of the macOS app's Swift sources (original
file noted in each module's doc comment). ~4,600 lines total.

```
src/
├── audio/
│   ├── mod.rs                  # PipeWire layer — one capture stream fanned out in-process
│   │                           #   to STT + four virtual sources (Recording/Claude/Codex/Llama)
│   └── memo_recorder.rs        # Accumulates memo samples; exports MP3 via ffmpeg on approval
├── config/
│   ├── mod.rs                  # QueuePopulatorConfig/AppConfig — JSON schema matches macOS app
│   ├── store.rs                # Load/save config.json — atomic tmp+rename, encrypt keys on save
│   ├── llm.rs                  # LLM provider tables (ported verbatim)
│   ├── secret_store.rs         # API-key encryption — shells out to repo `dc` tool
│   ├── env_resolver.rs         # Env var lookup w/ login-shell fallback (direnv secrets); cached
│   └── debug_log.rs            # stderr + ~/.config/queue-populator/debug.log (truncated per launch)
├── llm/
│   ├── mod.rs                  # Module exports
│   ├── client.rs               # Blocking HTTP via ureq — runs on coordinator's LLM worker thread
│   ├── prompt.rs               # Classification prompt builder (text copied verbatim)
│   ├── response.rs             # LLM response / ProposedEntry parsing
│   └── model_fetcher.rs        # Best-effort model list for config UI dropdown
├── queue/
│   ├── mod.rs                  # Module exports
│   ├── entry.rs                # QueueEntry serde types
│   ├── manifest.rs             # Allowed queue file list (copied verbatim)
│   └── writer.rs               # Validate vs manifest, mkdir, append sorted-key JSON lines
├── stt/
│   ├── mod.rs                  # Module exports
│   ├── engine.rs               # sherpa-onnx streaming zipformer; consumes 48 kHz mono f32 chunks
│   └── models.rs               # Model paths — ~/.local/share/queue-populator/models (QP_MODEL_DIR)
├── ui/
│   ├── mod.rs                  # Module exports
│   ├── app.rs                  # egui/eframe — transcript log + memo/entries review + config windows
│   ├── tray.rs                 # ksni StatusNotifierItem tray — state-colored icon + menu
│   └── sounds.rs               # Generated sine-blip WAV cues played via pw-play
├── coordinator.rs              # Owns state machine, phrase detector, transcript buffer, LLM
│                               #   worker, routing; single event channel on its own thread
├── state_machine.rs            # Pure AppState/AppEvent transitions — no IO, no UI
├── phrase_detector.rs          # Case-insensitive substring + token-window Levenshtein matching
├── lib.rs                      # Crate root — declares all modules
└── main.rs                     # Binary entry — wires audio, STT, UI, coordinator together
```
