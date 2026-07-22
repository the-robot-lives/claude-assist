# Project Architecture — Summary

## Overview

`utilities/agent/` is a grouping component in the Noizu Infra monorepo: seven
self-contained agent-centric DevOps utilities supporting AI-coding-agent workflows —
sandboxing (dangerously-safe, claude-desktop-sandbox), model routing (run-claude), skill
management (skill-manage), LLM-facing CLI docs (mallm), transcript indexing
(claude-assist), and declarative media generation (media-tool). No shared runtime; each
child has its own stack (Rust / TypeScript / Python / bash) and its own architecture docs.

## Children

- claude-assist — transcript indexer/browser: REST + SPA + TUI over SQLite FTS5/vec
- claude-desktop-sandbox — bwrap launcher, per-sandbox `$HOME` for claude-desktop
- dangerously-safe — agent-sandbox: Rust TUI + Docker composer for auto-approve agent runs
- mallm — LLM-friendly CLI documentation resolver for the repo's DevOps tools
- media-tool — `.media.prompt` YAML → 13-provider media generation with DAG + LLM eval
- run-claude — directory-aware model routing via front proxy (:4443) → LiteLLM (:4444)
- skill-manage — symlink/catalog manager enabling monorepo `trl-*` skills per provider

## Build & Install

Five-line fan-out Makefile: `SUBDIRS` + `../mk/subdirs.mk` forwards
build/compile/test/install/clean to children; repo-wide `make install-utilities` flows
through it. Most children install to `~/.local/bin`; mallm uses npm link, run-claude uses
`uv tool install`.

## Ecosystem Fit

Deliberately loosely coupled to utilities conventions: only media-tool's legacy bash
wrapper uses `share/k8-lib` and touches infra config; no child is an
`.infra-config.yaml` Docker/Helm target. Repo integration: skill-manage is the canonical
`skills/` enable mechanism; mallm documents repo CLIs for agents; run-claude routes agent
sessions' model traffic per directory.

## Key Decisions

Grouping directory not a project (no shared code); heterogeneous stacks chosen per-tool;
docs delegated to child summaries (one line + link at grouping level); loose infra
coupling — developer-host tools, not cluster services.
