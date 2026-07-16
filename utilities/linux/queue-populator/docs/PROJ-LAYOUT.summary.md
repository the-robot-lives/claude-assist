# Project Layout Summary — queue-populator (Linux)

```
queue-populator/
├── src/                            # Rust source → layout/src.md
│   ├── audio/                      #   PipeWire capture + virtual mics
│   ├── config/                     #   Config, LLM providers, secrets
│   ├── llm/                        #   LLM client/prompt/response
│   ├── queue/                      #   JSONL queue entry/manifest/writer
│   ├── stt/                        #   sherpa-onnx STT
│   ├── ui/                         #   egui + ksni tray + sounds
│   ├── coordinator.rs              #   Event loop
│   ├── state_machine.rs            #   Pure state transitions
│   ├── phrase_detector.rs          #   Phrase matching
│   ├── lib.rs                      #   Crate root
│   └── main.rs                     #   Entry point
├── config/
│   └── 10-robot-virtual-mics.conf  # PipeWire virtual sources
├── docs/
│   ├── PROJ-LAYOUT.md
│   ├── PROJ-LAYOUT.summary.md
│   └── layout/
├── Cargo.toml                      # Crate manifest
├── Cargo.lock
├── Makefile                        # Linux-gated compile/test/install
├── install.sh                      # Build + install everything
├── uninstall.sh
├── .gitignore                      # target/
└── README.md
```
