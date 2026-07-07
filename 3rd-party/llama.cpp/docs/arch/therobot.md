# therobot Extension Architecture

The therobot fork adds a single architecture family, `therobot`, to llama.cpp
as a **strict superset** of upstream. This document covers its design; the
authoritative fence/rebase checklist lives in
[../robot/patch-points.md](../robot/patch-points.md).

## Concept: family, not enum

`therobot` is not a new standalone architecture with its own graph. It is a
*family* that wraps an open-ended set of **donor** base architectures
(llama, qwen2, qwen2moe, qwen3, mamba, …). A therobot GGUF file declares which
donor it wraps and, optionally, a set of `therobot.*` extension features layered
on top. Base keys and tensors use the donor family's stock names, so the donor's
own loader and graph builder do the heavy lifting unchanged.

## Load path

`llama_model_create()` dispatches to `llama_robot_model_create()` (fenced
insertion `model-create`) when `general.architecture == "therobot"`. The factory:

1. **Parses + negotiates** the `therobot.*` contract via
   `llama_robot_hparams_load()` — validates spec version, resolves the donor
   `base_architecture` to an `llm_arch`, and negotiates declared features.
2. **Rebinds** the loader's per-arch KV formatting to the donor family so donor
   hyperparameters resolve under their stock key names.
3. **Instantiates** `llama_model_robot<TBase>` for the donor's model class, with
   `model->arch` set to the *donor* arch — so every base behavior switch (rope
   type, memory layout, chat template) acts as the donor.

```
llama_model_robot<TBase> : public TBase
  ├── load_arch_hparams()  ← inherited (donor)
  ├── build_arch_graph()   ← inherited (donor)   [E1: pure L0 passthrough]
  └── load_arch_tensors()  ← override: TBase::load_arch_tensors() + claim robot.* tensors
```

Extension tensors (`robot.*`, `blk.{L}.robot_*`) are *claimed* at load so the
loader's skip-unused-tensor accounting (`size_data -= nbytes; n_created++;`)
stays consistent; at the current stage their metadata is recorded but they are
not materialized into compute buffers.

## Feature contract (spec v1)

`therobot.features` lists required features; unknown-optional features are logged
and ignored, unknown-*required* or known-but-unimplemented features are refused.
Known features and their parsed sections:

| Feature | Section (`llama_robot_*_params`) | Idea |
|---------|----------------------------------|------|
| `taps` | `bottleneck` | Named channel-slice taps at `resid_post`/`attn_out`/`ffn_out` per block, with convert-time decodability/selectivity scores |
| `shims` | *(module files, spec §4)* | Shipped as separate `therobot-shim` module files, not inline |
| `state` | `state_params` | Leaky state banks (fast/mid/slow/glacial) carried across covered blocks |
| `modulator` | `modulator_params` | Low-dim named channels (arousal, valence, attention…) sourced from pooled/glacial state |
| `memory` | `memory_params` | Episodic key/value store with decay half-life + salience threshold |
| `delta` | `delta_params` | Delta inference — sparse block updates between dense-sweep heartbeats |
| `settle` | `settle_params` | Iterative settling (e.g. MDLM objective) with an m-arousal step schedule |

A **passthrough (L0)** file declares no required features and must behave
identically to the donor.

## Staged roadmap (E-stages)

The runtime is built in work packages; each gates the features it can accept.

| Stage | Delivers |
|-------|----------|
| **E1** *(current)* | Spec loader, feature negotiation, donor-wrapper factory, extension-tensor claim, `llama-robot-inspect`. Only L0 passthrough files run. |
| E2 | Taps (bottleneck insertion points) |
| E3 | Shims (module files) |
| E4 | State banks + modulator |
| E5 | Episodic memory |
| E6 | Delta inference |
| E7 | Settling |

A file requiring a known-but-unimplemented feature is refused with a distinct
error (vs. an unknown-feature refusal), so stage gates are explicit.

## Tooling

`tools/robot-inspect/` builds `llama-robot-inspect <model.gguf> [--load]`: it
reads the `therobot.*` manifest straight from GGUF metadata and prints identity,
negotiated features, per-feature sections, and extension tensors — also
understanding `therobot-shim` module files. Inspection uses
`llama_robot_hparams_load_gguf(..., negotiate=false)` so a file this build cannot
yet *run* can still be *inspected*. `--load` additionally exercises the full
runtime load path to verify acceptance.

## Superset invariant & rebase surfaces

Stock architectures and stock files must behave identically to upstream and the
upstream test suite must stay green. Guarantees:

- **New-file code** (`src/llama-robot-*`, `tools/robot-inspect/`, `docs/robot/`)
  is fork-only and never `#include`d by stock translation units — no conflicts.
- **Upstream touches** are minimal and fenced with `// ROBOT-EXT-BEGIN(<id>)` /
  `// ROBOT-EXT-END`. Six fences total (arch enum/name, model include/create,
  two build files) — see [../robot/patch-points.md](../robot/patch-points.md).
- **Rebase-sensitive contact surfaces** (relied on, not modified): the
  `llama_model_base` per-arch virtuals staying virtual; `llama_model_loader`
  public members used for KV rebind + tensor bookkeeping; arch-independent
  `LLM_TENSOR_NAMES`; donor model-class constructor signatures in
  `src/models/models.h`. Check these when a sync touches those files.

The one behavioral change a stock build can observe: the previously-invalid
architecture string `"therobot"` now loads instead of erroring.
