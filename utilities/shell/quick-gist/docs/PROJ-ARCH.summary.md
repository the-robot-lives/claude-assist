# Project Architecture — Summary

Single-file bash CLI wrapping `gh gist` with fzf-based interactive file selection.

**Dependencies:** `gh` (required), `fzf` (optional, interactive modes), `pbcopy` (optional, macOS clipboard — silently no-ops on Linux).

**Modes:** List (`-l`), Edit (`-e`), Append (`-a`), Pipe (`-p`), Create (default).

**Visibility:** Secret by default; overridden by flags or `QUICK_GIST_VISIBILITY` env var.

**Ecosystem:** Noizu `utilities/shell/` tool installed to `~/.local/bin` (own Makefile `install` target; `compile`/`test` no-ops for uniform Make interface). Self-contained — no `share/k8-lib/`, `.infra-config.yaml`, k8s, or Infisical coupling.

**Design:** Single portable script, no install dependencies beyond `gh`, graceful degradation without `fzf`.
