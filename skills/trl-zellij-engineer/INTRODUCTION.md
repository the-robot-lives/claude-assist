---
skill: trl-zellij-engineer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-16
---

# Zellij Engineer — Introduction

Extends and modifies Zellij, the Rust terminal workspace multiplexer. Covers four surfaces: WASM plugin development against the `zellij-tile` API, KDL configuration/layouts/keybinds/themes, core Rust internals (server threads, screen/tab/pane model, IPC, adding new actions), and downstream fork maintenance across upstream rebases. For engineers writing Zellij plugins, authoring layouts, contributing to Zellij core, or carrying patches on a fork. Produces plugin crates, KDL files, core patches, and review reports — grounded in a real Zellij checkout, never from memory.

## Input Contract

```yaml
inputs:
  arguments:
    - name: brief
      type: freeform
      required: true
      description: "What to build, change, or debug in Zellij — surface, goal, constraints"
      example: "Write a plugin that shows git branch in the status bar"

  file_conventions:
    - pattern: "A Zellij source checkout (Cargo.toml with zellij workspace members)"
      format: rust-workspace
      description: "Required for core work and strongly recommended for plugin work — the API surface is version-specific and must be read, not recalled"
      schema: "zellij/, zellij-server/, zellij-client/, zellij-utils/, zellij-tile/, default-plugins/"
      example: |
        zellij-tile/src/lib.rs      # ZellijPlugin trait
        zellij-utils/src/data.rs    # Event, EventType, Permission
    - pattern: "~/.config/zellij/config.kdl or a layout *.kdl"
      format: kdl
      description: "Existing config or layout, required for config/layout review or debugging workflows"
      schema: "Zellij KDL config or layout schema"
      example: |
        layout {
            pane split_direction="vertical" {
                pane
                pane
            }
        }

  context_expectations:
    - "Zellij version matters — the plugin API and KDL schema change across releases; confirm the version before answering"
    - "For fork work: a git checkout with an upstream remote configured"
    - "For plugin builds: a Rust toolchain with the wasm target installed"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Zellij plugin crate"
      path: "{plugin-name}/ (Cargo.toml + src/main.rs)"
      format: rust
      description: "Compilable WASM plugin implementing ZellijPlugin, with permissions, event subscriptions, and a load/build recipe"
      example: |
        register_plugin!(State);
        impl ZellijPlugin for State { ... }
    - name: "KDL config or layout"
      path: "config.kdl | layouts/{name}.kdl (or user-specified)"
      format: kdl
      description: "Validated layout, keybind block, theme, or plugin alias definition"
      example: |
        layout {
            tab name="main" { pane }
        }
    - name: "Core change plan or patch"
      path: "returned inline, or applied across the workspace crates"
      format: rust + markdown
      description: "Exhaustive touched-file list plus the edits — for cross-cutting changes like adding an Action, every layer from KDL parse through protobuf to the screen thread"
    - name: "Review report"
      path: "returned inline"
      format: markdown
      description: "Findings against the relevant checklist with severity, file:line citations, and fixes"

  side_effects:
    - "May build plugins to wasm and run cargo/xtask commands when asked"
    - "Never runs a rebase, force-push, or destructive git operation without explicit confirmation"

  handoff:
    - skill: trl-tui-engineer
      artifact: "Plugin UI layout"
      description: "Terminal UI design patterns for plugin render surfaces"
    - skill: trl-technical-writer
      artifact: "Plugin crate or core change"
      description: "README, changelog, and user-facing documentation"
    - skill: trl-story-to-release
      artifact: "Core change plan"
      description: "Carry a Zellij feature from story through verified release"
```

## Conventions

```yaml
conventions:
  naming:
    - "Plugin crates: kebab-case directory, snake_case crate name (default-plugins/status-bar)"
    - "Layouts and configs: kebab-case .kdl filenames"
    - "Core changes follow the existing crate's module conventions — match surrounding code"
  structure:
    - "Read the API before writing against it — cite file:line from the checkout, never recall signatures"
    - "Plugin state is a single struct registered via register_plugin!; all IO goes through shim functions"
    - "Cross-cutting core changes are enumerated as a complete file list before any edit is made"
    - "Fork patches stay minimal and localized to reduce rebase conflict surface"
  anti_patterns:
    - "Do not answer Zellij API questions from memory — the API is version-specific and moves fast; read the checkout"
    - "Do not use this skill for general terminal UI framework work (ratatui, bubbletea) — that is trl-tui-engineer"
    - "Do not use it for tmux/screen configuration — it is Zellij-specific"
    - "Do not add an Action or Event variant without updating every layer (KDL, CLI, protobuf, route, screen) — partial changes compile but fail at runtime"
    - "Do not rebase a fork without first inventorying the divergence"
  prerequisites:
    - "Rust toolchain; wasm target for plugin builds"
    - "For core work: ability to run cargo xtask commands in the checkout"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | Surface routing table and phased workflows |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | When running a specific workflow |
| 4 (plugins) | `references/plugins/plugin-api.md` | ZellijPlugin trait, events, permissions, shim API, pipes, workers, ui_components |
| 4 (plugins) | `references/plugins/plugin-development.md` | Scaffold, build, load, dev loop, debug |
| 4 (config) | `references/config/kdl-config.md` | Config schema, options, themes, plugin aliases |
| 4 (config) | `references/config/layouts.md` | Layout nodes, templates, swap layouts, floating panes |
| 4 (config) | `references/config/keybinds-and-actions.md` | Modes, bind syntax, the Action vocabulary |
| 4 (core) | `references/core/server-internals.md` | Crate map, threads, instruction enums, IPC, screen/tab/pane |
| 4 (core) | `references/core/adding-an-action.md` | The exhaustive cross-layer change recipe |
| 4 (core) | `references/core/testing-and-build.md` | xtask, unit/e2e tests, snapshot conventions |
| 4 (fork) | `references/fork-notes.md` | Downstream divergence inventory and rebase workflow |
| 5 (example) | `references/worked-example-plugin.md` | End-to-end plugin build walkthrough |
| 5 (example) | `references/worked-example-core-action.md` | End-to-end core action walkthrough |

## Quick Examples

### Build a plugin
`/trl-zellij-engineer write a plugin that lists open tabs and lets me fuzzy-jump to one`

### Author a layout
`/trl-zellij-engineer make me a dev layout: editor on the left, two stacked shells right, logs floating`

### Extend core
`/trl-zellij-engineer add a new action that toggles pane sync across all tabs`

### Rebase a fork
`/trl-zellij-engineer inventory our fork divergence and plan the rebase onto upstream main`
