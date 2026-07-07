# therobot runtime tests (E1)

Manual smoke tests for the therobot spec loader (E1). Not yet wired into
CMake/CI — that lands with the E0 CI gates (llamacpp-extensions.md §2). All
commands run from the repo root; `$BUILD` is a configured build directory.

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
