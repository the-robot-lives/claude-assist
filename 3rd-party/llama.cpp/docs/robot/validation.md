# Converting a model and vetting it on the therobot fork

The end-to-end runbook: take a stock HF checkpoint through the `robotgguf`
conversion pipeline, load the result on this fork, and prove — gate by gate —
that it is safe to serve. The governing principle throughout is the
function-preserving invariant: **at every stage there is a configuration of
the converted model that must reproduce the stock donor bit-for-bit**, and we
check that configuration before trusting anything the extensions add.

Companions: [`patch-points.md`](patch-points.md) (fork internals),
`projects/therobotgguf/convert/README.md` (pipeline usage),
`tests/robot/README.md` (per-feature test suites),
`projects/therobotgguf/arch/runtime/` (the specs these steps implement).

---

## Phase 0 — Prerequisites

**0.1 Build the fork** (CPU is sufficient for validation; v0 targets CPU
streaming anyway):

```bash
cd 3rd-party/llama.cpp
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=OFF
ninja -C build llama-robot-inspect llama-quantize
```

**0.2 Build the gate binaries** from `tests/robot/` (each is a standalone
executable against `libllama`):

```bash
for t in parity tap shim state memory delta settle registry; do
  g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_${t}_test.cpp \
      -Lbuild/bin -lllama -lggml -Wl,-rpath,$PWD/build/bin -o /tmp/robot_${t}_test
done
```

**0.3 Sanity-check the fork itself** before involving any real model — the
fixture suites must be green or nothing downstream is meaningful:

```bash
python3 tests/robot/make_donor_gguf.py gguf-py /tmp/robot-fixtures
python3 tests/robot/make_shim_ggufs.py gguf-py /tmp/robot-fixtures
/tmp/robot_parity_test /tmp/robot-fixtures/tiny-llama-stock.gguf /tmp/robot-fixtures/tiny-llama-therobot.gguf
# ... run the remaining seven suites per tests/robot/README.md — all must print OK
```

**0.4 Install the pipeline** and prepare the donor workspace:

```bash
cd projects/therobotgguf/convert
pip install -e '.[hf]'                 # HF stack needed for R0/R1/R3
cp configs/qwen2.5-1.5b.yaml configs/<donor>.yaml   # edit: donor id, corpus, sites
```

The per-donor YAML is the only thing you hand-edit. Every stage appends its
*measured* outputs to `configs/<donor>.lock.yaml`; the exporter refuses to
consume anything that isn't in the lockfile.

---

## Phase 1 — Establish the stock baseline

Nothing is comparable without a trusted reference.

**1.1 Convert the donor to a stock GGUF** with the fork's own converter (the
fork, not upstream, so tokenizer/KV handling matches the runtime that will
load it):

```bash
python3 3rd-party/llama.cpp/convert_hf_to_gguf.py <hf-checkpoint-dir> \
    --outfile work/<donor>-f16.gguf --outtype f16
```

**1.2 Record the baseline numbers** on this stock file, on the target
hardware: perplexity on a held-out set, your eval-suite scores, and decode
latency percentiles (p50/p95/p99 — percentiles, never means; 002 §4).
`llama-perplexity` and `llama-bench` from the fork build serve here. Save the
numbers into the lockfile's notes or alongside it; every later gate is a
delta against these.

**1.3 Confirm the stock file behaves identically in the fork as in upstream
llama.cpp** (superset invariant): same perplexity, and spot-check greedy
generations token-for-token. If this fails, stop — the fork has a regression
and no conversion result can be trusted.

---

## Phase 2 — Convert

Run the pipeline stages in order; each appends measured values to the
lockfile and each has a checkpoint you inspect before moving on.

**2.1 `robotgguf ingest` (R0).** Read the survey section of the lockfile:
layer count, dims, candidate cleave sites, the sanity generation. Vet: the
generation is coherent; candidate sites avoid block 0 and the final block.

**2.2 `robotgguf record` (R1).** Forward-hook recordings of the candidate
slices over the calibration corpus, plus weak labels for the attribute set.
Vet: the manifest binds model hash + corpus hash + spec version; sample
counts match across sites; **labels are real** (the stage warns loudly if the
weak-labeler pass hasn't replaced its placeholders — do not proceed on
placeholder labels).

**2.3 `robotgguf cleave` (R2).** Probe training and bottleneck selection.
Vet the lockfile's `cleave` section: 4–8 admitted bottlenecks; per-attribute
decodability above your configured bar with *selectivity* clearly positive
(the shuffled-control margin is what distinguishes signal from probe
capacity); stability near 1 across shards. Read the `findings` list —
attributes that aren't decodable in the frozen donor are dropped, and that is
a result, not a failure. Never force them.

**2.4 `robotgguf graft --steps 0` first (R3).** Always export a zero-init
graft before training one — this is the file Phase 3's parity gate runs on.
Then, on the GPU host, `robotgguf graft --steps N` for the trained variant:
KL-anchored to the frozen donor, new parameters only. Vet: the distillation
KL decreases and ends small; the training log never touches core parameters.

**2.5 `robotgguf calibrate` (R4).** Vet: per-block θ values are finite and
ordered sensibly; `achieved_keep_rate` is near the target; `max_staleness`
is acceptable against the chosen heartbeat.

**2.6 `robotgguf shims` (R5).** Vet the admission table: every admitted shim
moved its target attribute (positive effect) while the worst off-target
probe shift stayed below it; rejected shims list their reason. The output
`registry.json` is exactly what the runtime's E8 router loads — review the
tags and dependency/conflict declarations by hand once.

**2.7 `robotgguf export --out work/<donor>-therobot.gguf` (R7).** Two files
matter: the zero-graft export (from 2.4's first pass) and the trained export.
Vet: the extension-tensor list in the lockfile matches expectations;
`llama-robot-inspect work/<donor>-therobot.gguf` dumps a manifest whose
bottlenecks, banks, modulator channels, thresholds, and feature list all
match the lockfile.

**2.8 Quantize the base** (extensions stay f16/f32 automatically):

```bash
build/bin/llama-quantize work/<donor>-therobot.gguf work/<donor>-therobot-q8_0.gguf q8_0
```

---

## Phase 3 — Vet on the fork: the hard gates

These are ordered so each failure isolates a cause. Run all of them on the
zero-graft export first, then repeat the applicable ones on the trained
export and on each quantization you intend to serve.

**Gate 1 — Load + negotiation.**
`llama-robot-inspect <file> --load` must print `load check OK`. This
exercises spec-version checks, feature negotiation, KV rebinding to the donor
family, graft shape validation, and extension-tensor accounting.

**Gate 2 — L0 parity (the permanent invariant).**
`/tmp/robot_parity_test work/<donor>-f16.gguf work/<donor>-therobot.gguf`
on the **zero-graft** export must print `max |logit diff| = 0 … PARITY OK`.
Zero means zero: out_proj is zero, FiLM is identity, delta is off, memory
heads are inert — any nonzero diff is a bug in the export or the fork, full
stop. Re-run after quantizing: quantized-base parity is checked
extended-vs-stripped (see Gate 3) since quantization itself changes logits.

**Gate 3 — Strip interop.**
`robotgguf strip <extended> <stripped>` then `llama-robot-inspect <stripped>
--load`, and parity-test *stripped vs the stock base*. The stripped twin is
also the fixture for quantized parity: quantize both the extended and the
stock file identically and compare those.

**Gate 4 — Feature toggle matrix.**
For each feature independently: enabled-but-inert vs active. Concretely, on
the trained export measure perplexity + eval suite + latency percentiles for:
baseline (no shims attached, delta off, m at baseline), each admitted shim
attached alone, delta enabled, and m primed. Record every cell. The
acceptance bars come from the stage gates: trained grafts hold perplexity
within the band declared in the config; delta holds quality delta under 1%
at the measured keep rate (the S4 bar is ≥2× effective-FLOP cut — read it
from `llama_robot_delta_keep_rate`).

**Gate 5 — Behavioral probes** (these justify the project; a failure here is
a *finding* that branches the plan, per planning.md's rule):

- *Taps/probes:* during generation, `llama_robot_tap_read` +
  `llama_robot_probe_eval` report attribute values that agree with the R2
  probes' offline accuracy on fresh text.
- *Shim selectivity, live:* attach each admitted shim and re-measure its
  target attribute via the probes on generated text — the R5 admission
  scores must reproduce against the live runtime, and detaching must restore
  bit-exact baseline logits (the E3/E8 zero-forgetting property).
- *Priming (M3):* `llama_robot_mod_set` induces a measurable behavioral bias
  that decays back to baseline at the rate implied by σ(mod.alpha).
- *Memory (Hypothesis 4):* one `llama_robot_memory_write` changes behavior on
  the post-onset decode and the influence decays to <5% of peak while the
  memory persists; session save/load replays exactly.
- *Delta divergence:* streaming with delta on vs dense, divergence stays
  bounded and heartbeat sweeps visibly re-anchor it (compare against a
  long-heartbeat run).
- *Settle (if applicable):* settled output equals greedy AR on the jacobi-ar
  objective; rounds-to-settle correlates with difficulty.

The fixture test binaries are the templates for all of these — point the
same logic at the real model via the `llama-robot.h` API.

**Gate 6 — Serving drill (E8).**
Load `registry.json`, route a request tag set, decode, hot-swap to a second
tag set on the same context, route to empty, and confirm the empty-routed
logits are bit-identical to never-routed. Then run a soak: N requests with
random tag sets on a resident model, watching for leaks or drift.

**Gate 7 — Session lifecycle.**
Mid-conversation `llama_robot_session_save`, continue, restore, and confirm
the restored continuation reproduces the earlier one exactly. Export a memory
trace and confirm the consolidation pipeline can parse it.

---

## Phase 4 — Sign-off

A conversion is servable when: Gates 1–3 pass bit-exact on the zero-graft
export; Gates 1, 3–7 pass on the trained export at every quantization you
ship; the toggle matrix is recorded next to the lockfile; and the lockfile +
registry + baseline numbers are committed together (they are one provenance
unit — the runtime warns on hash mismatches between them for a reason).

Failures route as follows: Gate 1–3 failures are export/runtime bugs (fix
before anything else); Gate 4 regressions are training-quality problems (back
to R3/R5 with the recordings you already have); Gate 5 failures are research
findings (write them down; branch the plan); Gate 6–7 failures are runtime
serving bugs. Re-running any stage only ever *appends* to the lockfile, so
the audit trail of what was measured when survives iteration.
