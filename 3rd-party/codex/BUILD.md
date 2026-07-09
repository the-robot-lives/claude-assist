# Building & Installing Codex CLI

This is a vendored copy of OpenAI's Codex CLI (Rust workspace under `codex-rs/`).
See `docs/install.md` and `docs/contributing.md` for the upstream reference.

## Option 1: Install the prebuilt release

No build required.

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
# or
npm install -g @openai/codex
# or
brew install --cask codex
```

## Option 2: Build from source (this checkout)

### One-time toolchain setup

```bash
cd codex-rs

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup component add rustfmt clippy
cargo install --locked just
cargo install --locked dotslash
cargo install --locked cargo-nextest
```

### Build

```bash
cargo build
```

### Run without installing

```bash
cargo run --bin codex -- "explain this codebase to me"
```

### Install the binary onto PATH

```bash
cargo build --release
cp target/release/codex ~/.local/bin/codex   # or wherever your PATH picks up local bins
```

## Useful `just` targets (run from repo root; wraps `codex-rs`)

- `just install` — `rustup show active-toolchain && cargo fetch`
- `just fmt` / `just fmt-check` — formatting
- `just clippy` — lint
- `just test` — full nextest suite (`just test -p codex-tui` to scope to one crate)
- `just codex *args` — `cargo run --bin codex --`
- `just bazel-codex` / `just build-for-release` — build/run via Bazel instead of Cargo

## System requirements

| Requirement                 | Details                                                          |
| ---------------------------- | ----------------------------------------------------------------- |
| Operating systems           | macOS 12+, Ubuntu 20.04+/Debian 10+, or Windows 11 **via WSL2**  |
| Git (optional, recommended) | 2.23+ for built-in PR helpers                                    |
| RAM                         | 4-GB minimum (8-GB recommended)                                  |
