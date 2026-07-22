# Architecture Summary — utilities/

Top-level grouping directory for all Noizu Infra DevOps tooling: ten
self-contained child groups (agent, colo, database, k8, linux, mk, osx, shell,
start-app-scaffold, terraform). No runtime code at this level — only a fan-out
`Makefile`, the shared `mk/` include package, a `source_up` `.envrc`, and
`push-3rd-party-images.sh` (3rd-party image mirroring to ops.noizu.com).
Federated, not framework-based: uniformity comes from conventions, not shared
code.

## Shared Conventions

- Recursive Make contract via `mk/subdirs.mk` (target probing, graceful skip,
  build→compile fallback); `check-subdirs.sh` lints SUBDIRS consistency
- Install to `~/.local/bin`, shared libs to `~/.local/share/` (k8-lib)
- Infra-facing tools resolve repo-root `.infra-config.yaml` +
  `.envrc.k8.dc` solely through `share/k8-lib`, with `K8_*` env-first overrides

## Build & Install

Repo-root `make install-utilities` → `utilities/Makefile` install loop over
`SUBDIRS_NO_OSX` (osx installs via its own sudo/launchd mechanisms); generic
build/compile/test/clean dispatch through `mk/subdirs.mk`.

## Coupling Spectrum

Tightly infra-coupled (k8, database, terraform, colo: k8-lib +
.infra-config.yaml + dc→Infisical secrets flow) → loosely coupled
developer-host tools (agent, shell, start-app-scaffold; several serve
multi-agent fleet workflows) → decoupled desktop apps (linux, osx).

## Key Decisions

Grouping dirs over a framework (independent packages, one install fan-out);
capability-probed recursion across heterogeneous stacks; flat `~/.local/bin`
composition — tools shell out to siblings, config is the shared interface;
platform gating centralized in linux/ and osx/; Bash for wrappers, Rust for
correctness/secret-safety/TUI. Child internals documented in each group's own
`docs/PROJ-ARCH.summary.md`; Helm charts live upstream in noizu-infra.
