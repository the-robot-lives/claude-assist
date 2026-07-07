# Project Layout (Summary)

Quick structural reference for tools/agents. Keep in sync with `PROJ-LAYOUT.md`.
`[fork]` marks therobot-fork additions over upstream llama.cpp.

```
llama.cpp/
├── include/                   # Public C/C++ headers (llama.h, llama-cpp.h)
├── src/                       # llama core library
│   ├── llama-model.cpp        #   Model load, graph build, arch registry
│   ├── llama-context.cpp      #   Inference context + state
│   ├── llama-kv-cache.cpp     #   KV cache variants
│   ├── llama-sampler.cpp      #   Sampling
│   ├── llama-vocab.cpp        #   Tokenizer / vocab
│   ├── llama-grammar.cpp      #   GBNF grammar
│   ├── llama-robot-hparams.*  #   [fork] therobot spec parser + feature negotiation
│   ├── llama-robot-model.*    #   [fork] donor-wrapper model template + factory
│   └── models/                #   Per-architecture graph builders
├── ggml/                      # GGML tensor library (include/ + src/backends)
├── common/                    # Shared C++ utils for tools/examples
├── conversion/                # HF->GGUF Python adapters (per arch)
├── gguf-py/                   # Python package for reading/writing GGUF
├── tools/                     # Runnable binaries (server, cli, ...)
│   └── robot-inspect/         #   [fork] llama-robot-inspect — dump therobot manifest
├── examples/                  # Minimal example programs
├── tests/                     # C++ test suite
├── app/                       # Top-level `llama` CLI binary
├── models/                    # Test fixtures + chat templates
├── grammars/                  # GBNF grammars
├── vendor/                    # Vendored single-header libs
├── scripts/                   # Dev, bench, sync, validate scripts
├── pocs/                      # Proofs of concept
├── benches/                   # Benchmark result snapshots
├── docs/                      # Documentation
│   └── robot/                 #   [fork] therobot extension docs (patch-points)
├── cmake/                     # CMake toolchains, presets, pkg-config
├── ci/                        # CI runner
├── .devops/                   # Dockerfiles per backend
├── .github/                   # Workflows, actions, PR template
├── requirements/              # Pinned Python requirements
├── CMakeLists.txt             # Root CMake build
├── CMakePresets.json          # CMake presets
├── Makefile                   # Wrapper over CMake
├── flake.nix                  # Nix dev shell
├── pyproject.toml             # Python project + tool config
├── AGENTS.md                  # AI-agent contribution rules (read first)
├── CONTRIBUTING.md            # Contribution guide
├── README.md                  # Start here
└── LICENSE                    # MIT
```
