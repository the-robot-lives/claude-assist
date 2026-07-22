# Project Architecture — Summary

## Overview

Terminal-workspace utility package: five bash launchers plus one KDL layout
that open zellij sessions/tabs/panes pre-wired for agentic development —
Claude Code or Codex prefilled left, nvim right, shell bottom, optional
floating dev-server preview pane. Core mechanism: generate a temporary KDL
layout at runtime (one tab per directory picked via fzf or a workspace YAML)
and launch `zellij -s <session> -n <layout>`; incremental tools extend live
sessions via `zellij action`. Agent commands are prefilled on the input line
(zsh `vared` / bash `read -e -i`), not auto-run.

## Core Components

- `bin/zj-claude` — session with a claude dev tab per selected directory (fzf, workspace YAML, --cerebras/--zai)
- `bin/zj-codex` — same generator, queues codex instead
- `bin/zj-spawn` — generic tab-per-subdir (or 4x4 grid) with arbitrary command
- `bin/zj-tab` — add one claude dev tab to current session (or start one)
- `bin/zj-panes` — split the current tab in a live session into the standard panes
- `layouts/claude-dev.kdl` — static single-tab version of the dev layout
- `Makefile` — installs bin/* to ~/.local/bin and layouts to ~/.config/zellij/layouts

## Key Decisions

- Prefill agent commands for human Enter-to-confirm; unknown shells degrade to printing.
- Runtime-generated KDL (temp file, EXIT-trap cleanup) because tab count/cwds are dynamic.
- Session names truncated to 20 chars (macOS 104-byte socket path limit); timestamp suffix on collision.
- Explicit kdl_escape + printf %q escaping across the KDL/shell quoting layers.
- Self-contained: no share/k8-lib, no .infra-config.yaml; only zellij, fzf, optional yq/nvim.

## Ecosystem Fit

Installed by repo-root `make install-utilities` via the package Makefile;
purely local developer ergonomics for running multi-project agent fleets in
zellij; `run-claude with <provider>` shorthands hook into sibling wrapper
tooling on PATH.
