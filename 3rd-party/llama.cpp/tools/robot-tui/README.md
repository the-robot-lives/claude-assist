# robot-tui

A [ratatui](https://ratatui.rs) + [crossterm](https://docs.rs/crossterm) terminal
front-end for **therobot** models. The left pane is the chat; the right pane is
the live extension state — modulator channels, per-tap probe classes, the
episodic-memory list (index / salience / age), recall magnitude, and delta
keep-rate. One token is generated per frame so the right pane animates as the
model decodes.

It talks to `libllama` over FFI and uses the `robot-ffi` C shim to drive
llama.cpp's own `common_sampler` (full sampler parity with `llama-cli`). The
therobot introspection comes straight from the C-ABI in `include/llama-robot.h`.

## Why Rust here

The equivalent C++ (`tools/robot-cli`, a fork of `llama-cli`) hand-rolled a TUI
with raw ANSI escapes, alt-screen bookkeeping, and manual `termios` — fragile and
awkward to maintain inside a 700-line upstream fork. crossterm owns raw mode /
alt screen / resize / key events, and ratatui gives a real layout engine and
widgets, so the UI code is small and robust. `robot-cli` is parked (left in-tree,
out of the build) in favor of this.

## Build

1. Build llama.cpp with common + the shim (Metal example):

   ```zsh
   echo "configure with common on"
   cmake -S 3rd-party/llama.cpp -B 3rd-party/llama.cpp/build -DLLAMA_BUILD_COMMON=ON

   echo "build the sampler shim (pulls in llama + llama-common)"
   cmake --build 3rd-party/llama.cpp/build --target robot-ffi -j
   ```

2. Build the Rust binary (point it at that build dir if not ../../build):

   ```zsh
   echo "build the TUI"
   cd 3rd-party/llama.cpp/tools/robot-tui
   ROBOT_LLAMA_BUILD=/Users/keithbrings/Work/Space/Infra/Noizu/3rd-party/llama.cpp/build cargo build --release
   ```

## Run

```zsh
echo "launch"
MODEL=/Users/keithbrings/Work/Space/Infra/Noizu/projects/therobotgguf/convert/work/qwen3.5-0.8b-therobot-L3.gguf
./target/release/robot-tui -m $MODEL
```

Type a line + Enter to chat. Commands: `/reset` (clear session + memory),
`/quit`; `Esc` or `Ctrl-C` exits.

## Notes / tuning

- `build.rs` links `libllama` + the ggml backend libs dynamically and `robot-ffi`
  + `llama-common` statically. The **ggml library names differ by platform and
  backend** (Metal / BLAS / CUDA / Vulkan split libs). If linking fails, look at
  what `cmake` actually produced under `build/` and adjust the `rustc-link-lib`
  lines in `build.rs`.
- Probes run a compute graph on the backend, so they are only evaluated at turn
  boundaries (`with_probes = true`) when no decode is in flight — this is what
  keeps the Metal command queue from being corrupted by concurrent access. The
  other read-outs are host-side struct reads, sampled every frame.
- Generation is one token per frame; raise the poll cadence in `run()` if you
  want faster streaming at the cost of input latency.
