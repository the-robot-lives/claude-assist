# therobot runtime tests (E1 + E2 + E3)

Manual smoke tests for the therobot spec loader (E1), bottleneck taps (E2),
and the shim engine (E3). Not yet wired into CMake/CI — that lands with the
E0 CI gates (llamacpp-extensions.md §2). All commands run from the repo root;
`$BUILD` is a configured build directory.

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

# negotiation: files requiring not-yet-implemented features must still refuse
$BUILD/bin/llama-robot-inspect /tmp/robot-fixtures/l2-manifest.gguf --load   # expect: load check FAILED ('state' unimplemented)
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

E3 notes: shim tensors must be f32 (v1); `modulator:` gates parse but refuse
to load until the E4 modulator bus exists; probe-gate scores come from the
shim's own `robot.shim.gate.weight` projection with the comparison folded into
an effective bias at load (`step()` in-graph, so `>` is strict and `>=`
behaves like `>`); a shim must outlive the contexts it is attached to.
