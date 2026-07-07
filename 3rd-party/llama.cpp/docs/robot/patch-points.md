# therobot fork — patch points

Every touch inside an upstream file is fenced with `// ROBOT-EXT-BEGIN(<id>)` /
`// ROBOT-EXT-END` markers (llamacpp-extensions.md §2). This document is the
authoritative checklist for upstream rebases: after a sync, verify each fence
below survived (grep `ROBOT-EXT` and diff against this list), re-run the parity
gates, and update this file whenever a fence is added, moved, or removed.

New-file extension code (no fences needed, never conflicts):

- `src/llama-robot-hparams.{h,cpp}` — spec v1 parser + feature negotiation
- `src/llama-robot-model.{h,cpp}` — donor-wrapper template + factory
- `tools/robot-inspect/` — manifest inspection tool (`llama-robot-inspect`)
- `tests/robot/` — fixture generators + L0 parity test (manual; see its README)
- `docs/robot/` — this documentation

## Fenced insertions in upstream files

| # | File | Fence id | What it does |
|---|------|----------|--------------|
| 1 | `src/llama-arch.h` | `arch-enum` | Adds `LLM_ARCH_THEROBOT` to the `llm_arch` enum (immediately before `LLM_ARCH_UNKNOWN`) |
| 2 | `src/llama-arch.cpp` | `arch-name` | Adds `{ LLM_ARCH_THEROBOT, "therobot" }` to `LLM_ARCH_NAMES` |
| 3 | `src/llama-model.cpp` | `model-include` | `#include "llama-robot-model.h"` |
| 4 | `src/llama-model.cpp` | `model-create` | In `llama_model_create(llama_model_loader &, ...)`: dispatch `LLM_ARCH_THEROBOT` files to `llama_robot_model_create()` |
| 5 | `src/CMakeLists.txt` | `build-src` | Adds `llama-robot-hparams.cpp`, `llama-robot-model.cpp` to the `llama` target |
| 6 | `tools/CMakeLists.txt` | `build-tools` | `add_subdirectory(robot-inspect)` |
| 7 | `tests/.gitignore` | `tests-gitignore` | Un-ignores `tests/robot/` (manual E1 smoke tests) |

## Upstream internals relied on without modification

These are not patches, but rebase-sensitive contact surfaces — check them when
a sync touches the listed files:

| Surface | Used by | Assumption |
|---------|---------|------------|
| `llama_model_base` virtuals (`load_arch_hparams` / `load_arch_tensors` / `build_arch_graph`) | `llama_model_robot<TBase>` | class-per-arch dispatch stays virtual |
| `llama_model_loader` public members `arch_name`, `llm_kv`, `weights_map`, `metadata`, `n_created`, `size_data` | factory + tensor claim | KV formatter rebind and the skip-unused-tensor bookkeeping pattern (`size_data -= nbytes; n_created++;`) keep working |
| `LLM_TENSOR_NAMES` being arch-independent | wrapper | donor tensor names resolve without per-arch tables |
| Donor model classes `llama_model_llama`, `llama_model_qwen2`, `llama_model_qwen2moe`, `llama_model_qwen3`, `llama_model_mamba` (`src/models/models.h`) | `llama_robot_model_mapping()` | constructor signature `(const llama_model_params &)` |

## Superset invariant

Stock architectures and stock files must behave identically to upstream; the
upstream test suite must stay green. The only behavioral change a stock build
can observe is that the previously-invalid architecture string `"therobot"`
now loads instead of erroring.
