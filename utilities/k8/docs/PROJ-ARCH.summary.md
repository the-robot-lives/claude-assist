# Architecture Summary — utilities/k8

Grouping directory: the Kubernetes DevOps tool suite of the Noizu monorepo —
seven self-contained utility packages forming the build → push → deploy →
operate pipeline for the self-hosted k8s platform. Six packages are standalone
Bash CLI collections (plus one Rust binary in secret-utils); `k8-lib` is the
shared sourced-shell library all others load at runtime from `$K8_LIB_DIR`
(`~/.local/share/k8-lib`). All tools install flat to `~/.local/bin` via the
fan-out `Makefile` (`../mk/subdirs.mk`, driven by repo-root
`make install-utilities`).

Style: flat composition over shared config. Packages never import each
other's code — higher-level tools (`deploy-service`) shell out to sibling
executables on PATH; all converge on repo-root `.infra-config.yaml`
(structural) + `.envrc.k8.dc` / `K8_*` env vars (scalars), parsed solely by
k8-lib with env-first override precedence.

## Packages

- **k8-lib** — shared library: config facade, output helpers, Docker/Helm discovery, `--assist`
- **docker-utils** — image build/push, BuildKit multi-arch, Infisical patch versions
- **helm-utils** — tiered helm upgrades w/ MD5 change detection, rollback, OCI publish
- **infra-utils** — orchestration: `deploy-service` pipeline, `infra-config`, `infra-init`
- **secret-utils** — Rust `infisical` CLI/TUI + legacy Bash; dc ↔ YAML ↔ Infisical sync
- **cluster-utils** — seven `cluster-*` inspection dashboards
- **staging-utils** — staging lifecycle wrappers over helm-upgrade/kubectl

Child internals documented in each child's own `docs/PROJ-ARCH.summary.md`.

## Key Decisions

- Flat bin, no inter-script imports; composition by shelling out to siblings
- Single config source of truth resolved only through k8-lib
- `K8_*` env-first overrides — agent/CI-safe per invocation
- Infisical as monotonic version + secret authority
- Bash-first, single Rust exception; stage handoff via `.docker-state/`/`.helm-state/`
- Helm charts live in the upstream noizu-infra repo
