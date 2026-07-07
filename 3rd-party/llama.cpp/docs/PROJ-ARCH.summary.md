# Project Architecture (Summary)

Quick reference for tools/agents. Keep in sync with `PROJ-ARCH.md`.

## Overview

llama.cpp is a layered C/C++ GGUF inference engine: `ggml` (portable tensor
library + per-hardware backends) at the bottom, the `llama` runtime library
(`src/`) in the middle, and binaries + Python conversion tooling on top. The
stable C API `include/llama.h` is the only public surface. This checkout is the
**therobot fork** — a strict superset adding a `therobot` architecture family
that wraps a donor base arch (llama/qwen2/mamba/…) with an optional feature
contract; stock builds behave identically to upstream except `"therobot"` now loads.

## Core Components

- `include/llama.h` — stable public C API, single consumer entry point
- `src/llama-model.cpp` — model load, weight mapping, per-arch graph build, arch registry
- `src/llama-context.cpp` / `llama-kv-cache.cpp` — inference context, batching, KV cache
- `src/llama-sampler.cpp` / `llama-vocab.cpp` / `llama-grammar.cpp` — sampling, tokenizer, GBNF
- `src/models/` — per-architecture graph builders (class per arch)
- `ggml/` — portable tensor library + one backend per hardware target
- `conversion/` + `convert_hf_to_gguf.py` + `gguf-py/` — HF→GGUF tooling
- `tools/` — `llama-server`, `llama-cli`, and *(fork)* `llama-robot-inspect`
- `src/llama-robot-*` *(fork)* — therobot spec parser + donor-wrapper model template

## Runtime Data Flow

C API opens a GGUF → `llama_model_load` reads `general.architecture`, picks the
per-arch model class, maps weights, builds the graph → `llama_context` schedules
batches onto the selected ggml backend → vocab tokenizes, sampler picks tokens
(optionally grammar-constrained). Models are produced offline by Python
`conversion/` tooling from HuggingFace weights.

## therobot Extension *(fork)*

`architecture == "therobot"` dispatches to a fork factory that parses the
`therobot.*` KV contract, negotiates features (refusing unknown-required or
unimplemented), and wraps the donor model class as `llama_model_robot<TBase>`
with `model->arch` = the donor. Current stage (E1) is L0 passthrough: extension
tensors are claimed for loader accounting but not yet computed. Upstream edits
are fenced (`ROBOT-EXT-BEGIN/END`); staged roadmap E1→E7 adds taps, shims,
state+modulator, memory, delta, settling. Details in `arch/therobot.md`.

## Technology Stack

C++17 core, C public ABI, Python 3 tooling. CMake + presets build (Makefile
wrapper, Nix flake, Apple xcframework script). Backends: CPU/CUDA/Metal/Vulkan/
SYCL/HIP/MUSA/CANN/OpenCL/RPC. GGUF model format. Server via vendored
cpp-httplib + nlohmann/json. GitHub Actions CI, per-backend Dockerfiles.

## Key Decisions

- Layered ggml (hardware-facing) ↔ llama (model-facing) split — add backends without touching model code
- Stable C ABI as the only public surface — insulates churning C++ internals
- Class-per-architecture dispatch — each arch owns its graph builder
- GGUF self-description — runtime configures from the file, no external config
- therobot as a fenced superset (new files + inventoried fences), not a patch fork — keeps rebases mechanical and the stock test suite green
