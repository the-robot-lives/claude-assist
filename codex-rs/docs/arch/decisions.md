# Architecture Decisions

## Crate-Oriented Boundaries

The workspace favors small crates with explicit responsibilities. Shared runtime behavior lives in `codex-core`, but new standalone concepts should prefer specialized crates when that keeps dependencies narrow and avoids further core growth.

## Protocol Crates For Contracts

Public and internal wire shapes live in protocol crates such as `protocol`, `app-server-protocol`, and `exec-server-protocol`. This keeps message schemas reviewable, supports generated artifacts, and lets clients depend on contracts without importing runtime implementation.

## App-Server As Rich Client Boundary

Rich clients communicate through app-server JSON-RPC. This boundary gives external clients the same thread, turn, item, model, permission, plugin, filesystem, and process lifecycle used by first-party app-server client paths.

## Policy-Controlled Execution

Command execution is isolated behind local and remote execution layers. Sandbox policy, approval decisions, and platform-specific backends are handled below UI and transport code so behavior remains consistent across CLI, TUI, app-server, and remote environments.

## Persistent Thread Model

Conversations persist as threads, turns, items, rollout records, and state database rows. That model supports resume, fork, archive, delete, review, compaction, and inspection workflows without requiring clients to reconstruct history themselves.

