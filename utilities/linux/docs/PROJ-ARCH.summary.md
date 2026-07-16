# Architecture Summary — utilities/linux

## Overview

Grouping directory for Linux-only desktop utilities in the Noizu Infra
monorepo. No source of its own: a thin Makefile (`SUBDIRS :=
queue-populator`) includes the shared `utilities/mk/subdirs.mk` harness to
fan `build`/`compile`/`test`/`install`/`clean` out to self-contained child
projects. Child Makefiles gate on Linux, so monorepo-wide builds skip this
branch on other platforms.

## Core Components

- `Makefile` — subdirs fan-out via `../mk/subdirs.mk`; `make help` lists targets
- `queue-populator/` — voice-driven Ubuntu GNOME / PipeWire utility (Rust):
  wake-phrase memo capture, on-device sherpa-onnx STT, LLM classification to
  JSONL queue, live-mic routing into four persistent PipeWire virtual
  sources; port of `utilities/osx/queue-populator`. Internals documented in
  the child's own `docs/` (PROJ-ARCH.summary.md, PROJ-LAYOUT.summary.md).

## Ecosystem Fit

Children are compiled desktop apps, not shell tools: they do not source
`share/k8-lib` and are not `.infra-config.yaml` docker/helm targets.
Integration with the monorepo is via the make subdirs harness and, where
needed, the `dc` secret tool (queue-populator's encrypted API keys). Children
install their own binaries to `~/.local/bin` via their `install.sh`.

## Key Decisions

- Platform gating centralized under `linux/` (sibling `osx/` for macOS ports)
- Self-contained children own build/install/docs; this level only routes
- New Linux utilities: add sibling folder, append to `SUBDIRS`
