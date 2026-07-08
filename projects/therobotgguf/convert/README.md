# robotgguf — the conversion pipeline (workstream C)

Retrofits existing LLM checkpoints onto the therobot runtime
([`../arch/runtime/conversion-pipeline.md`](../arch/runtime/conversion-pipeline.md)).
The prime directive holds end-to-end: the donor core is frozen from the moment
of recording, every graft is function-preserving at insertion, and the
pipeline's own verify stage proves it against the live runtime — a converted
model with all extensions at init is **bit-for-bit the donor** (checked, not
asserted).

## Usage

The current primary target is **Qwen3.5-0.8B** (`configs/qwen3.5-0.8b.yaml`,
with donor-specific instructions in `configs/qwen3.5-0.8b.md`); the
`qwen2.5-1.5b.yaml` config remains as the reference for a pure-attention
donor. Substitute your config below.

```bash
cd projects/therobotgguf/convert
pip install -e .            # numpy + pyyaml; `pip install -e '.[hf]'` for R0/R1/R3 training
robotgguf --config configs/qwen2.5-1.5b.yaml ingest      # R0  [HF stack]
robotgguf --config configs/qwen2.5-1.5b.yaml record      # R1  [HF stack]
robotgguf --config configs/qwen2.5-1.5b.yaml cleave      # R2
robotgguf --config configs/qwen2.5-1.5b.yaml graft       # R3  (--steps N trains; 0 = zero-init)
robotgguf --config configs/qwen2.5-1.5b.yaml calibrate   # R4
robotgguf --config configs/qwen2.5-1.5b.yaml shims       # R5
robotgguf --config configs/qwen2.5-1.5b.yaml settle      # R6  (config only, v0)
robotgguf --config configs/qwen2.5-1.5b.yaml export --out work/qwen-therobot.gguf   # R7
robotgguf --config configs/qwen2.5-1.5b.yaml verify --parity-bin /tmp/robot_parity_test  # R8
```

Stages append *measured* values to `<config>.lock.yaml`; the exporter consumes
only measured values, never hand-entered ones. `robotgguf strip <in> <out>`
downgrades an extended file for stock-llama.cpp interop.

## Status

| Stage | State |
|---|---|
| R0 ingest, R1 record, R3 graft training | implemented, **untested** — need a GPU/checkpoint host (`pip install '.[hf]'`); the graft's zero-init path runs anywhere and is tested |
| R2 cleave, R4 calibrate, R5 shims, R7 export/strip, R8 verify | implemented and covered by `tests/e2e_test.py` |
| R6 settle | config passthrough (v0 policy: diffusion-class donor through R0–R5; the runtime's `jacobi-ar` objective works on any causal donor) |
| Weak labelers (R2 label source) | heuristic v0 in `robotgguf/labelers.py` — sentence-granular, seven attributes, wired into `record`; `robotgguf relabel` regenerates labels from stored tokens without re-running the model; a teacher-LLM pass can overwrite `labels/<attr>.npy` later (same contract). Tested by `tests/labelers_test.py` |

## End-to-end test (no GPU needed)

Runs synthetic recordings (a legitimate stand-in — recordings are the
versioned contract) through cleave → graft(init) → calibrate → shims →
export → verify against the fork's tiny fixture donor:

```bash
python3 tests/e2e_test.py /tmp/robot-fixtures <fork-root> /tmp/robot-build/bin /tmp/robot_parity_test
# expect: CONVERSION E2E: OK — including a bit-exact parity gate on the export
```

Requires the fork built (`llama-robot-inspect`) and the fixture set from
`<fork>/tests/robot/make_donor_gguf.py`.
