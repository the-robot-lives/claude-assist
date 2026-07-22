# Architecture Summary — secret-bucket

## Overview

Single-binary Rust CLI for agent-safe manipulation of local secret files
(`.envrc`, `.envrc.dc`, `.envrc.k8.dc`). Commands `list`, `diff`, `copy`,
`set` operate on typed bucket addresses and emit value-free output (key names
and statuses only), keeping secrets out of agent transcripts and logs.
Optional privilege-separated mode: root-installed binary + narrow sudoers
rule + root-owned policy allowlist.

## Core Components

Single-file crate (`src/main.rs`): clap CLI layer; `Address` parser for
`envrc:<file>[:VAR]` and `dcfile:<file>:<bucket>[:yaml.path]`; envrc provider
(export-line parse/rewrite); dcfile provider (dc_yaml heredoc + flattened YAML
paths); policy engine (canonicalized read/write/value_file allowlists);
value-free emit/report functions.

## Data Flow

Parse address → policy authorization (if `--policy`) → provider dispatch.
Diff compares values in memory, prints only names grouped as
same/changed/missing_left/missing_right. Copy/set move values without
printing them; `set` reads from an allowlisted `--value-file`, never argv.

## Key Decisions

Rust single binary (no shell leak paths, auditable sudo target); value-free
logging contract enforced by sentinel-based tests; canonicalized path
allowlist instead of sandboxing; text-splicing edits preserve surrounding
file content; new values via file, never command-line argument.

## Ecosystem Fit

Standalone Rust tool under `utilities/shell/` — does not use `share/k8-lib`
or `.infra-config.yaml`. `make install` → `~/.local/bin` per repo convention
(picked up by `make install-utilities`, skipped if cargo absent). Complements
the `dc` tool and Infisical secrets pipeline as the agent-safe file-level
diff/copy primitive prescribed in root CLAUDE.md.

## Stack

Rust 2021; clap, serde/serde_yaml/serde_json, anyhow; tempfile (dev);
size-optimized release profile; Cargo.lock committed.
