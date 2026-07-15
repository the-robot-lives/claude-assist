# Zellij Engineering — Project Tracker

> Copy this file into your project and fill it in as work proceeds.
> One tracker per Zellij change (plugin, layout, core feature, or rebase).

## Identity

| Field | Value |
|-------|-------|
| **Change name** | |
| **Surface** | plugin / config-layout / core / fork-rebase |
| **Zellij version** | *(from workspace Cargo.toml — the API is version-specific)* |
| **Checkout path** | |
| **Upstream ref** | *(fork work only)* |
| **Owner** | |
| **Started** | |

## Goal

*One paragraph: what changes for the user when this ships.*

## Grounding Checklist

The API moves fast; recalled signatures are a top failure mode. Confirm before writing code.

- [ ] Zellij version read from `Cargo.toml`, not assumed
- [ ] Relevant API read from the checkout with file:line noted below
- [ ] Existing in-repo precedent identified (a default plugin, a similar Action, a comparable layout)

| Thing I need | Read at (file:line) | Confirmed |
|--------------|--------------------|-----------|
| | | ☐ |
| | | ☐ |

## Scope

### In scope
-

### Out of scope
-

## Surface-Specific Sections

### If plugin

| Item | Value |
|------|-------|
| Crate name / path | |
| Permissions requested | |
| Events subscribed | |
| Pipes handled (CLI / plugin) | |
| Workers used | |
| Build target | |
| Load mechanism | file: / zellij: / alias |

- [ ] `register_plugin!` wired to state struct
- [ ] Permissions requested in `load()` and handled on grant
- [ ] Subscribed only to events actually used
- [ ] Renders correctly at 80×24 and on resize
- [ ] Builds to wasm cleanly
- [ ] Loads and runs in a live session

### If config / layout

- [ ] Parses without error (`zellij setup --check` or a live load)
- [ ] Behaves correctly at small terminal sizes
- [ ] Swap layout constraints verified (min/max/exact panes)
- [ ] No hardcoded absolute paths that break for other users

### If core

- [ ] Complete touched-file list enumerated **before** editing (see `references/core/adding-an-action.md`)
- [ ] Every layer updated: KDL parse, CLI, protobuf/plugin API, route, screen/tab
- [ ] Existing precedent traced end-to-end as the template
- [ ] Unit tests added/updated
- [ ] Snapshot tests reviewed, not blindly accepted
- [ ] Builds: `cargo xtask build`
- [ ] Tests: `cargo xtask test`

| Layer | File | Done |
|-------|------|------|
| Action definition | | ☐ |
| KDL parsing | | ☐ |
| CLI action | | ☐ |
| Plugin API / protobuf | | ☐ |
| Routing | | ☐ |
| Handler | | ☐ |

### If fork rebase

| Field | Value |
|-------|-------|
| Fork base (last upstream merge) | |
| Target upstream ref | |
| Commits to carry | |

- [ ] Divergence inventoried by feature (see `references/fork-notes.md`)
- [ ] High-conflict seams identified
- [ ] Rebase performed on a scratch branch first
- [ ] Full build + test pass post-rebase
- [ ] Live smoke test in a real session

## Verification

*Zellij is an interactive terminal app — a clean compile proves very little. Record what you actually drove.*

| Check | How exercised | Result |
|-------|--------------|--------|
| | | |

## Decisions & Rationale

| Decision | Alternatives considered | Why |
|----------|------------------------|-----|
| | | |

## Open Questions / Risks

-

## Status

| Phase | Status | Notes |
|-------|--------|-------|
| Grounding | ☐ not started / ☐ in progress / ☐ done | |
| Design | ☐ / ☐ / ☐ | |
| Implementation | ☐ / ☐ / ☐ | |
| Verification | ☐ / ☐ / ☐ | |
| Docs | ☐ / ☐ / ☐ | |
