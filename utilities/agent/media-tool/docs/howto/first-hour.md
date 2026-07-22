# How to: install media-tool and generate your first asset

**Goal:** go from a fresh checkout to a real generated image in under 5 minutes.
**Prereqs:** `cargo`/Rust toolchain on PATH (falls back to a Python engine if absent); a `GEMINI_API_KEY` ([get one](https://aistudio.google.com/apikey)) exported or resolvable via `.envrc.k8.dc` at `$INFRA_ROOT`.

1. Build and install the binary to `~/.local/bin`:
   ```bash
   cd utilities/agent/media-tool
   make install
   ```
   This runs `cargo build --release` and installs `generate-media-prompt`. No `cargo`? It falls back to the legacy bash+Python engine automatically.

2. Preview the plan for a bundled demo prompt — no API calls, no key required:
   ```bash
   generate-media-prompt --dry-run --verbose demos/image/sample-logo.media.prompt
   ```
   You should see a `Generation plan` block naming the provider (`gemini`), model, and the exact output path — followed by `✅ Dry run complete — no API calls made`.

3. Make sure your key is visible, then generate for real:
   ```bash
   export GEMINI_API_KEY="..."
   generate-media-prompt demos/image/sample-logo.media.prompt
   ```

**Verify:** the file named in the dry-run's `Output:` line now exists — `demos/image/sample-logo.png` — and the CLI prints a success line for the prompt.

**Gotchas:**
- No API key resolvable → the tool dies immediately with a named-key error (this is deliberate, not a bug); export the var or add it under `.envrc.k8.dc`.
- `--force` is required to regenerate over an existing output file — the default is skip-if-exists, so a second run of step 3 with no `--force` will report "skipped, already exists" rather than overwrite.
- Building for the first time downloads and compiles the full dependency tree (tokio/reqwest/ratatui/clap); expect a couple of minutes on first `make install`.

Next: write your own prompt file — see `HOW-TO.md` for a template per asset type (image, SVG, diagram, HTML, voice, music, video), and skim `README.md` for the full schema.
