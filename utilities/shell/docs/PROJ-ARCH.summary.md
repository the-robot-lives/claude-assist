# Project Architecture — Summary (utilities/shell)

Grouping directory (not an application): eleven self-contained shell/terminal
utilities with no shared runtime. This level contributes only aggregation — a
`Makefile` whose `SUBDIRS` delegates build/compile/test/install/clean through
shared `../mk/subdirs.mk` (target introspection, graceful skip, build→compile
fallback), and a `source_up` `.envrc`. Child internals live in each child's
own `docs/PROJ-ARCH.summary.md`.

## Children

- **auto-sudo** (Rust+zsh) — rule-based automatic sudo elevation
- **direnv-config** (Rust+SDKs) — `dc` layered YAML config/secret store; bridges to Infisical pipeline
- **github-utils** (Bash) — deepest-first bulk submodule commit/push; sole k8-lib consumer
- **make-repo** (Bash) — gh-wrapped repo create/edit/fork
- **misc-git-utils** (Bash+Rust) — git shortcuts + doc-pointers durable links
- **quick-gist** (Bash) — gh gist wrapper with fzf
- **remote-tunnel** (Bash) — autossh reverse + flag-gated ngrok tunnels; installs to `~/bin`
- **repo-lock** (Rust) — session locks + git commit mutex for concurrent agents
- **secret-bucket** (Rust) — value-free secret list/diff/copy
- **tabbing-on** (Rust+sh) — tab title/status/theme manager; optional dc-mode dep on sibling direnv-config
- **zellij** (Bash+KDL) — zj-* agent-workspace launchers

## Ecosystem Fit

All install to user PATH (`~/.local/bin` convention) via repo-root
`make install-utilities` recursion. Only github-utils uses `share/k8-lib`;
no child reads `.infra-config.yaml` — developer-machine tooling, decoupled
from deploy metadata. Several tools exist for multi-agent fleet workflows
(repo-lock, secret-bucket, zellij, tabbing-on).

## Key Decisions

Grouping over framework (no imposed shared library); introspected uniform Make
interface; Bash for thin wrappers, Rust where correctness/secret-safety/TUI
demands it; value-free output contract across secret-adjacent tools.
