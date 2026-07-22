# Project Architecture — Summary

Self-contained bash CLI wrapping `gh gist` with personal-account selection, filtered NUL-safe multi-file picking, incremental uploads, large-text chunking, and explicit success/failure reporting.

**Dependencies:** `gh` (required), `fzf`/`rg` (interactive discovery), `split` (large files), and an optional platform clipboard command.

**Modes:** List (`-l`), Edit (`-e`), Append (`-a`), Pipe (`-p`), Create (default).

**Visibility:** Secret by default; overridden by flags or `QUICK_GIST_VISIBILITY` env var.

**Ecosystem:** Noizu `utilities/shell/` tool installed to `~/.local/bin` (own Makefile `test` and `install` targets). Self-contained — no `share/k8-lib/`, `.infra-config.yaml`, k8s, or Infisical coupling.

**Design:** One runtime script, process-local account tokens, recursive file filters, incremental mutation with partial-result reporting, and mocked regression coverage.
