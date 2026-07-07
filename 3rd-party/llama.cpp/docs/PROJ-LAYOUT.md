# Project Layout

llama.cpp is a C/C++ inference engine for LLMs in the GGUF format. It is built on
two layered C++ libraries: `ggml/` (tensor math + hardware backends) and `src/`
(the high-level `llama` API — model loading, context, KV cache, sampling, vocab).
Python tooling in `conversion/` and `gguf-py/` converts HuggingFace models to
GGUF. Runnable binaries live under `tools/`.

This is the **therobot fork**: a strict superset of upstream that adds a
`therobot` architecture family (new-file code under `src/llama-robot-*` plus
fenced `// ROBOT-EXT-BEGIN`/`END` insertions in upstream files). See
`docs/robot/patch-points.md` for the authoritative rebase checklist.

```
llama.cpp/
├── include/                   # Public C/C++ headers
│   ├── llama.h                #   Stable C API
│   └── llama-cpp.h            #   C++ wrapper over the C API
├── src/                       # llama core library → [layout/src.md](layout/src.md)
│   ├── llama.cpp              #   API entry / dispatch
│   ├── llama-model.cpp        #   Model load, graph build, architecture registry
│   ├── llama-context.cpp      #   Inference context + state
│   ├── llama-kv-cache.cpp     #   KV cache variants
│   ├── llama-sampler.cpp      #   Sampling strategies
│   ├── llama-vocab.cpp        #   Tokenizer / vocab
│   ├── llama-grammar.cpp      #   GBNF grammar constraining
│   ├── llama-robot-hparams.*  #   [fork] therobot GGUF spec parser + feature negotiation
│   ├── llama-robot-model.*    #   [fork] donor-wrapper model template + factory
│   └── models/                #   Per-architecture graph builders
├── ggml/                      # GGML tensor library → [layout/ggml.md](layout/ggml.md)
│   ├── include/               #   Public GGML/GGUF headers
│   └── src/                   #   Core + one dir per hardware backend
├── common/                    # Shared C++ utils for tools/examples → [layout/common.md](layout/common.md)
├── conversion/                # HF->GGUF Python adapters (per arch) → [layout/conversion.md](layout/conversion.md)
├── gguf-py/                   # Python package for reading/writing GGUF
├── tools/                     # Runnable binaries (server, cli, ...) → [layout/tools.md](layout/tools.md)
│   └── robot-inspect/         #   [fork] `llama-robot-inspect` — dump a GGUF's therobot manifest
├── examples/                  # Minimal example programs → [layout/examples.md](layout/examples.md)
├── tests/                     # C++ test suite
│   ├── test-backend-ops.cpp   #   Per-backend op correctness
│   ├── test-tokenizer-*.cpp   #   Tokenizer tests
│   ├── test-sampling.cpp      #   Sampler tests
│   ├── peg-parser/            #   PEG parser tests
│   └── snapshots/             #   Golden-output fixtures
├── app/                       # Top-level `llama` CLI binary
│   ├── llama.cpp              #   thin main() wrapper
│   └── download.cpp           #   Model download helper
├── models/                    # Test fixtures + chat templates
│   ├── *.gguf                 #   Tiny reference models for tests
│   ├── *.inp / *.out          #   Tokenizer input/golden-output pairs
│   └── templates/             #   Jinja chat templates per model
├── grammars/                  # GBNF grammars (json, c, chess, ...)
├── vendor/                    # Vendored single-header libs
│   ├── cpp-httplib/           #   HTTP server/client
│   ├── nlohmann/              #   JSON
│   ├── stb/                   #   stb_image (multimodal)
│   ├── miniaudio/             #   Audio (TTS input)
│   └── sheredom/              #   subprocess.h
├── scripts/                   # Dev, bench, sync, validate scripts
│   ├── server-*.py            #   Server bench/test harnesses
│   ├── sync-ggml.sh           #   Mirror GGML upstream
│   ├── get-*.sh               #   Fetch eval datasets
│   ├── apple/                 #   Apple-platform validation
│   ├── hip/  jinja/  snapdragon/
│   └── sync_vendor.py         #   Refresh vendored headers
├── pocs/                      # Proofs of concept (vdot / q8dot)
├── benches/                   # Benchmark result snapshots (per hardware)
├── docs/                      # Upstream documentation
│   ├── build.md               #   Build instructions (the canonical build ref)
│   ├── autoparser.md          #   Auto chat-template parser
│   ├── function-calling.md    #   Tool/function calling
│   ├── development/           #   HOWTO-add-model, parsing, perf
│   ├── backend/               #   Per-backend build notes (CUDA, Metal, SYCL...)
│   ├── multimodal/            #   Per-MM-model guides
│   ├── ops/                   #   Op-support matrices per backend (.csv)
│   └── robot/                 #   [fork] therobot extension docs (patch-points rebase checklist)
├── cmake/                     # CMake toolchains, presets, pkg-config templates
├── ci/                        # CI runner (run.sh) + MUSA notes
├── .devops/                   # Dockerfiles per backend (cuda, rocm, vulkan, ...)
├── .github/                   # Workflows, composite actions, PR template
├── requirements/              # Pinned Python requirements (per task)
├── CMakeLists.txt             # Root CMake build
├── CMakePresets.json          # CMake presets
├── Makefile                   # Convenience wrapper over CMake
├── build-xcframework.sh       # Build Apple .xcframework
├── flake.nix                  # Nix dev shell
├── pyproject.toml             # Python project + tool config
├── requirements.txt           # Aggregate Python deps
├── .clang-format  .clang-tidy # C++ style
├── .editorconfig              # Editor settings
├── .pre-commit-config.yaml    # Pre-commit hooks
├── mypy.ini  pyrightconfig.json  ty.toml  .flake8   # Python lint/type config
├── .gitignore  .gitmodules  .dockerignore  .ecrc
├── AGENTS.md                  # AI-agent contribution rules (read first)
├── CONTRIBUTING.md            # Contribution guide
├── README.md                  # Start here
├── SECURITY.md                # Security policy
├── CODEOWNERS                 # Code ownership map
├── AUTHORS                    # Contributor list
└── LICENSE                    # MIT
```

## Key Files

| File | Purpose |
|------|---------|
| `include/llama.h` | The stable public C API — entry point for all consumers |
| `CMakeLists.txt` + `CMakePresets.json` | Root build definition and presets |
| `docs/build.md` | Canonical build instructions |
| `conversion/` + `convert_hf_to_gguf.py` | Convert HuggingFace models to GGUF |
| `tools/server/` | The OpenAI-compatible HTTP server (`llama-server`) |
| `AGENTS.md` | AI-agent rules — read before any change |
| `flake.nix` | Reproducible Nix dev environment |
| `docs/robot/patch-points.md` | [fork] therobot fence inventory — rebase/sync checklist |
| `src/llama-robot-hparams.*` | [fork] therobot GGUF spec v1 parser + feature negotiation |
