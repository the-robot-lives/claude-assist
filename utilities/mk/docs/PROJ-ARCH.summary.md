# Architecture Summary

## Overview

`utilities/mk` — dependency-free Make include package driving the recursive
Makefile tree under `utilities/`. Pure build-orchestration glue; no runtime.

## Core Components

- `subdirs.mk` — fans `SUBDIR_TARGETS` (build/compile/test/install/clean) out to `SUBDIRS` children; probes each child's `.PHONY` via `make -pn`, skips missing targets, falls back build→compile; each subdir name is itself a phony target.
- `check-subdirs.sh` — standalone linter: `[MISSING-FROM-PARENT]`, `[MISSING-SUBDIRS]`, `[MISSING-CHILD]`; non-zero exit for CI/pre-commit; prunes `mk/` itself.

## Ecosystem Fit

Root `make install-utilities` → `utilities/Makefile` (includes `mk/subdirs.mk`);
group Makefiles (agent, shell, k8, terraform, database, colo, linux, osx) each
include it too. Install into `~/.local/bin` is a custom loop in
`utilities/Makefile`, not `subdirs.mk`. No dependency on k8-lib or
.infra-config.yaml.

## Key Decisions

- Capability probing over blind recursion — children need no stub targets.
- build→compile fallback bridges script-only and compiled subprojects.
- Checker kept as separate script, independent of Make; excludes `mk/` from scans.
