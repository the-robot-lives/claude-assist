# Project Architecture — Summary

## Overview

`agent-sandbox` is a Rust TUI + docker image builder that runs coding agents
(claude / codex / opencode) in dangerous/auto-approve mode safely: each run gets
an isolated git worktree mounted into a per-project docker container with
controlled env, ports, mounts, and network. Supersedes the legacy
`bin/dangerously-safe` bash launcher (still installed alongside).

## Core Components

- CLI (`cli.rs`/`main.rs`): wizard, build-image, list-images, doctor, template, preview
- `tui/`: ratatui wizard; fixture-driven `preview` mode needs no docker/git
- `config/`: serde schema + deep-merge layering of `.agent-sandbox/config`
- `image/`: slug normalization, OCI-label registry, closest-subset reuse, Dockerfile composition, build
- `worktree/`: git worktree create/list under `.agent-sandbox/worktrees/`
- `launch/`: env passthrough, hooks, tool staging on PATH
- `docker/` + `compose/`: interactive `docker run`, or compose overlays with mitmproxy log sidecars
- `inference/`: optional LLM branch-name suggestion with deterministic fallback
- `snippets/`: dockerfile fragment library (base + per-app); `templates/`: bootstrap configs

## Image Reuse

Sorted app-set tags + `org.agent-sandbox.apps` label; exact match reused, else
closest subset image layered with delta apps, else build from base.

## Config Layering

`template <- parent configs (far→near) <- project`; mappings merge recursively,
scalars/sequences replaced by the higher layer.

## Launch Modes

Default: interactive `docker run` (`--network none` when internet disabled,
best-effort). Compose mode when config defines compose services: shared external
network, optional infra base, per-worktree overlay, optional mitmproxy
outbound-logging sidecars.

## Ecosystem Fit

Self-contained Rust crate; not tied to `.infra-config.yaml` or `share/k8-lib`.
Installs via `make install` / repo `make install-utilities`: binary + legacy
script to `~/.local/bin`, snippets to `~/.local/share/agent-sandbox/`,
templates to `~/.config/agent-sandbox/`.

## Key Decisions

Rust+ratatui over bash for wizard/merge/set logic; worktree-per-run isolation;
fragment-composed images with subset reuse; compose only when needed;
never-blocking inference fallback. Not yet wired: dc env layers,
post_container_start hook, mitmproxy intercept, push/multiarch, true egress control.
