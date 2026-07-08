# therobot runtime tests (E1–E8)

Manual smoke tests for the therobot spec loader (E1), bottleneck taps (E2),
the shim engine (E3), state banks + modulator (E4), episodic memory (E5), the
delta executor (E6), the settling decoder (E7), and accretion serving (E8).
Not yet wired into CMake/CI — that lands with the E0 CI gates
(llamacpp-extensions.md §2). All commands run from the repo root; `$BUILD` is
a configured build directory.

## Fixtures

```bash
# manifest fixtures: L0 passthrough, L2-style manifest, unknown-feature file, shim module
python3 tests/robot/make_test_ggufs.py gguf-py /tmp/robot-fixtures

# loadable twins: tiny llama donor as stock file + identical-weight therobot L0 file
python3 tests/robot/make_donor_gguf.py gguf-py /tmp/robot-fixtures
```

## Manifest dump + negotiation

```bash
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/l0-passthrough.gguf
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/l2-manifest.gguf   # dumps despite unimplemented features
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/bad-feature.gguf   # warns: unknown required feature
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/shim.gguf          # therobot-shim module manifest
```

## Runtime load path (feature negotiation enforced)

```bash
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/tiny-llama-therobot.gguf --load   # expect: load check OK
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/tiny-llama-stock.gguf    --load   # stock path, expect OK
```

Expected in the log: `therobot: L0 passthrough file`, the donor hparams read
via `llama.*` keys, and `therobot: claimed extension tensor robot.mod.alpha`.

## L0 parity gate

A therobot passthrough file must produce logits identical to its stock twin
(permanent invariant, runtime README §5):

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_parity_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_parity_test
/tmp/robot_parity_test /tmp/robot-fixtures/tiny-llama-stock.gguf /tmp/robot-fixtures/tiny-llama-therobot.gguf
# expect: max |logit diff| = 0 ... PARITY OK
```

## E2 taps + probes

`tiny-llama-taps.gguf` (from `make_donor_gguf.py`) is an L1 file requiring
`taps`: two bottlenecks (mid-layer `resid_post` slice, last-layer `ffn_out`
slice) and an identity probe head with 0.5 bias on tap 0. The test covers:
tap metadata via `llama-robot.h`, graceful failure before any decode and on
bad ids, logit parity with taps active (taps are pure outputs), finite
non-trivial tap reads at both cleave points, `probe(x) == x + 0.5` exactly,
and tap refresh across decodes.

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_tap_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_tap_test
/tmp/robot_tap_test /tmp/robot-fixtures/tiny-llama-stock.gguf /tmp/robot-fixtures/tiny-llama-taps.gguf
# expect: E2 TAP TEST: OK

# negotiation: taps/shims/state/modulator are implemented; l2-manifest.gguf now
# passes negotiation and fails later for the honest reason (it is a
# manifest-only fixture with no donor tensors)
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/l2-manifest.gguf --load   # expect: load check FAILED (missing donor hparams)
```

Deferred from E2: the `llama-server` `/robot/taps` endpoint — server-side slot
semantics (which sequence's taps a request refers to) are better settled
together with E8's per-request routing; the C API above is the contract it
will mirror.

## E3 shims

Shim modules (`make_shim_ggufs.py`) target the `subject` bottleneck of
`tiny-llama-taps.gguf`: an always-on `steer` (+1), a gain ×2 behind a probe
gate that deterministically fires / never fires, and depends/conflicts
fixtures. The test covers: exact slice edits read back through the (post-shim)
tap, downstream logit movement, bit-exact detach parity, in-graph gate on/off,
composition in attach order, hot attach/detach mid-session on one context
(graph-reuse epoch invalidation), and registry metadata enforcement.

```bash
python3 tests/robot/make_shim_ggufs.py gguf-py /tmp/robot-fixtures
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_shim_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_shim_test
/tmp/robot_shim_test /tmp/robot-fixtures/tiny-llama-taps.gguf /tmp/robot-fixtures
# expect: E3 SHIM TEST: OK
```

E3 notes: shim tensors must be f32 (v1); probe-gate scores come from the
shim's own `robot.shim.gate.weight` projection with the comparison folded into
an effective bias at load (`step()` in-graph, so `>` is strict and `>=`
behaves like `>`); a shim must outlive the contexts it is attached to.

## E4 state banks + modulator

`make_donor_gguf.py` emits three L2 variants: `tiny-llama-l2.gguf` (all grafts
at function-preserving init — out_proj zero, γ-bias 1, everything else 0),
`tiny-llama-l2-film.gguf` (β = m[arousal] at layer 0), and
`tiny-llama-l2-state.gguf` (live leaky-state branch on layer 0). The test
covers: bit-exact zero-graft parity across multiple decodes; the M3 priming
demo — `llama_robot_mod_set` induces a logit bias that relaxes monotonically
back to baseline through per-channel decay (σ(0) = 0.5 per decode); state
carry across identical KV-cleared decodes; exact session checkpoint/rollback
via `llama_robot_session_save/load` (the 003 §4 mind-checkpoint); and a
`modulator:arousal>2` gated shim firing/shutting off exactly with m.

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_state_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_state_test
/tmp/robot_state_test /tmp/robot-fixtures/tiny-llama-stock.gguf /tmp/robot-fixtures
# expect: E4 STATE TEST: OK
```

E4 notes and v1 limits: one recurrent state per context (batch-1 /
single-sequence streaming — the project's v0 target); m updates once per
ubatch (pooled over its positions), not per token; the leaky-state scan is
unrolled over the ubatch (~5·T nodes per covered layer — size `n_ubatch`
accordingly); state on the final layer is refused at load (its rows are
output-filtered); grafted tensors must be f32. Session state rides the
dedicated `llama_robot_session_*` API — integration with
`llama_state_get_data/set_data` is deferred until cross-version session-file
compatibility is worked out.

## E5 episodic memory

`tiny-llama-l2-mem.gguf` has silent salience weights (only explicit
`llama_robot_memory_write` stores) and β = m[arousal] so recall is visible in
logits; `tiny-llama-l2-mem-auto.gguf` has live salience weights for the
quantile-gated auto-write path. The test covers Hypothesis 4 end-to-end: a
single write changes behavior with no weight update (rises to a peak while
recall is fresh, then decays monotonically to <5% of peak through the
4-token recency halflife + m decay), the memory itself persisting while its
influence fades; `memory_forget`; non-positive-salience refusal; capacity-4
decay-based eviction; the v2 session blob carrying the full mind (store +
recall + clock); warmup suppressing auto-writes and the salience gate opening
after it, capacity-bounded.

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_memory_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_memory_test
/tmp/robot_memory_test /tmp/robot-fixtures
# expect: E5 MEMORY TEST: OK
```

E5 notes and v1 limits: memory requires taps + modulator, and `value_dim`
must equal the modulator dim (recall lives in modulator space); recall is
injected into the *next* decode's modulator update, so behavior onset lags
one decode; surprise is the −log p of the incoming token under the previous
decode's last-position distribution (not checkpointed — the first
post-restore decode reads surprise 0); auto-writes need salience > 0, an
8-decode warmup, and salience ≥ the running-window quantile.

## E6 delta executor

Three 3-layer fixtures cover blocks 1–2 with modulator-coupled excitability
(1e6 per unit of m[arousal]): `tiny-llama-delta-lo.gguf` (θ = 0, heartbeat 4),
`tiny-llama-delta-hi.gguf` (θ = 1e6, heartbeat 4), and
`tiny-llama-delta-nohb.gguf` (θ = 1e6, heartbeat 1000). The test covers:
delta OFF by default; always-firing delta matching dense to blend round-off
(≤1e-4); the exact heartbeat fire schedule (3 fires per block over 12 tokens,
keep rate 0.25) via the compute-trace API; heartbeat sweeps bounding
divergence (drift with heartbeat ≤ drift without); excitability priming
(`mod_set` fires a block outside the schedule — 002's "anxious streams fire
easier" coupling); prompt ubatches running dense without polluting the trace,
with streaming resuming on a dense sweep.

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_delta_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_delta_test
/tmp/robot_delta_test /tmp/robot-fixtures
# expect: E6 DELTA TEST: OK
```

E6 notes and v1 limits: blocks still *execute* — the fire flag gates whether
their output enters the stream, giving exact delta semantics, the full
compute trace, and bounded-divergence behavior; physically skipping quiet
blocks is the shared `llama-robot-executor` optimization E6/E7 converge on
(same interface, deferred — the DoD's ≥2× FLOP cut reads from the trace as
*effective* FLOPs until then). Coverage is declared by
`blk.{L}.robot_delta.theta_base` presence (block 0 excluded); θ compares
mean-squared input change; fatigue tensors (`.fatigue.rho/.gain`) are
optional and default to off; prompt ubatches (T > 1) always run dense; delta
holds are per-context execution cache, deliberately outside the session
checkpoint (a dense sweep re-initializes them within one heartbeat).

## E7 settling decoder

`tiny-llama-settle.gguf` declares `settle` (objective `jacobi-ar`, mask token
0, step cap 64, ε 0, m_schedule [0,1,2,4]) plus a modulator and one tap. The
`llama_robot_settle` canvas loop — built on `llama-robot-executor`, the
shared iterate-until-quiet control structure — drafts every position, then
re-decodes the molten canvas each round (prompt KV stays warm; the canvas
region is dropped and re-decoded in one batch). The test proves: the settled
canvas **equals the greedy AR output exactly** (the jacobi-ar fixed point),
rounds bounded by canvas length + 1; rounds track difficulty (shorter canvas
⇒ ≤ rounds — 004 test 2 flavor); arousal 3 adds exactly its 4 scheduled
re-check rounds and those re-checks don't disturb the settled canvas; taps
stay readable across settling; argument errors are rejected.

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_settle_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_settle_test
/tmp/robot_settle_test /tmp/robot-fixtures
# expect: E7 SETTLE TEST: OK
```

E7 notes and v1 limits: only the `jacobi-ar` objective is implemented —
masked-diffusion (`mdlm`) objectives refuse at load until a Dream/LLaDA-class
donor path exists, and the `llama-robot-settle` CLI tool + `llama-server`
settle mode are deferred with it (the C API is the contract they will wrap);
commit is prefix-stability (which is what makes the greedy-AR equality
exact); the m-schedule indexes on the arousal channel at settle entry (m
keeps decaying underneath — the leaky state persisting across settling
rounds is the un-commit escape hatch, not a bug); the optional
`robot.settle.len.*` length head is not consumed yet (callers provide the
canvas length).

## E8 accretion serving

`make_shim_ggufs.py` emits `registry/` — ten modules `r0..r9` (integer steers
so stacked effects are measurable) indexed by `registry.json` with tags,
admission scores, and the dependency graph: `r8` depends on `r0`, `r9`
conflicts with `r8`. The test covers the S6 DoD: ten modules hot-loaded and
routed per-request on one resident context (route alpha → beta swaps sets
without teardown; the wide route keeps 9 non-conflicting modules with exact
stacked effect); dependency auto-include (`gamma` pulls `r0` in);
first-admitted-wins conflict resolution (`r9` skipped beside `r8`, attaches
alone via its own tag); the zero-forgetting invariant — `route(none)` is
**bit-identical** to a never-routed context (005 test 2); and
`llama_robot_memory_export` writing the consolidation pipeline's raw material
(JSON with provenance, m, and the salience-stamped entries).

```bash
g++ -std=c++17 -Iinclude -Iggml/include tests/robot/robot_registry_test.cpp \
    -L$BUILD/bin -lllama -lggml -Wl,-rpath,$BUILD/bin -o /tmp/robot_registry_test
/tmp/robot_registry_test /tmp/robot-fixtures
# expect: E8 REGISTRY TEST: OK
```

E8 notes: routing manages only registry-loaded modules (manually attached
shims are untouched); module files stream in lazily on first routing and are
owned by the registry — free the registry only after the contexts routed from
it; consolidation *training* is the offline Python pipeline's job — the
runtime exports traces and loads distilled modules, nothing more. The
`llama-server` routing endpoint follows when the server surface lands
(deferred with E2's `/robot/taps`).
