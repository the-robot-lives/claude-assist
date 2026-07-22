# Architecture Summary — k8-lib

## Overview

Shared sourced-shell library for the Noizu k8 devops tool suites (docker-build,
docker-push, helm-upgrade, helm-rollback, helm-publish, deploy-service,
infra-init). Installed to `~/.local/share/k8-lib`; no executables — commands
source modules from `bin/` via `$K8_LIB_DIR`. Core design: a layered
configuration facade around `.infra-config.yaml` plus direnv-config scalars.

## Core Components

- `common.sh` — output helpers (step/ok/warn/fail/die) + config bootstrap
- `config.sh` — exports resolved `K8_*` variables
- `config-resolver.sh` — config file discovery + scalar resolution accessors
- `docker-config.sh`, `docker-vsn.sh` — Docker target discovery, version/tag logic
- `helm-common.sh`, `helm-publish-config.sh` — chart discovery, tiers, namespaces, OCI publish
- `project-registry.sh` — per-project `project.yaml` loader (deploy-service wiring)
- `assist.sh` — `--assist` AI help via headless Claude Code
- `all/repos/terraform/import/iam/state_upgrade/cleanup/doctor/help.sh` — `infra-init` `cmd_*` subcommands
- `Makefile` — install + `bash -n` syntax test; `*.example` config templates

## Configuration Resolution

- File discovery: `--config` → `$K8_CONFIG` → `$INFRA_ROOT/` → git-root walk → `$K8_LIB_DIR/`
- Scalars: env var → `dc get k8 <path>` → YAML fallback → hardcoded default
- Requires mikefarah yq; paths in `.infra-config.yaml` are relative to the file

## Module Families

1. Library/config modules — side-effect-free function definitions, double-source guarded
2. infra-init subcommand modules — `cmd_<name>()` entry points, assume common.sh loaded

## Ecosystem Fit

Sole parser of the monorepo root `.infra-config.yaml` (tiers, namespaces,
Docker/Helm targets); scalar secrets via direnv-config `.envrc.k8.dc`;
installed alongside consuming commands by `make install-utilities`.

## Key Decisions

- Sourced library, not executables — one place for shared behavior
- Env-first scalar precedence — per-invocation overrides for CI/agents
- Git-root walking discovery — works from any monorepo subdirectory
- Direct IAM import bypassing terraformer (hangs on 1000+ managed policies)
- `bash -n` syntax check as the only automated test
