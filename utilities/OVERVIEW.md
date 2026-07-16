# Utilities — Catalog

The `utilities/` tree is the DevOps toolbox for the Noizu Infra monorepo: self-contained
CLI packages grouped by domain (agent, colo, database, k8, linux, osx, shell, terraform)
plus the shared `mk/` Make harness and the `start-app-scaffold` project generator. Repo-root
`make install-utilities` fans out through `mk/subdirs.mk`, installing tools flat to
`~/.local/bin` (and shared libs to `~/.local/share/`). Tools compose by shelling out to
siblings on PATH, not by importing each other. Coupling runs a spectrum: infra-facing groups
(k8, database, terraform, colo) resolve `.infra-config.yaml` + `.envrc.k8.dc` **only** through
`share/k8-lib`, while developer-host tools (agent, shell) and desktop apps (linux, osx) stay
decoupled. Per-group and per-tool detail lives in each dir's `docs/PROJ-ARCH.md`.

**Maturity legend:** experimental · alpha · beta · stable · mature · legacy — judged from tests,
README depth, recency, and arch-doc signals, not lines of code.

### agent/ — AI-coding-agent workflow tooling ([overview](agent/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [claude-assist](agent/claude-assist/docs/PROJ-ARCH.md#overview) | Agent-transcript indexer/browser | REST + SPA + TUI over SQLite FTS5/vec (pnpm/TS) | beta |
| [claude-desktop-sandbox](agent/claude-desktop-sandbox/docs/PROJ-ARCH.md#overview) | Multi-instance claude-desktop launcher | bwrap per-sandbox `$HOME` isolation (bash) | stable |
| [dangerously-safe](agent/dangerously-safe/docs/PROJ-ARCH.md#overview) | Sandboxed auto-approve agent runner (agent-sandbox) | Rust TUI + Docker composer; Rust successor to the legacy bash sandbox | beta |
| [mallm](agent/mallm/docs/PROJ-ARCH.md#overview) | LLM-friendly CLI docs resolver | Surfaces repo DevOps-tool docs to agents (Node CLI) | beta |
| [media-tool](agent/media-tool/docs/PROJ-ARCH.md#overview) | `.media.prompt` YAML → media generation | 13 providers, DAG + LLM-eval quality selection (Rust) | mature |
| [run-claude](agent/run-claude/docs/PROJ-ARCH.md#overview) | Directory-aware model routing | Front proxy :4443 → LiteLLM :4444, self-healing watchdog (Python) | stable |
| [skill-manage](agent/skill-manage/docs/PROJ-ARCH.md#overview) | Skill symlink/catalog manager | Canonical `skills/` enable mechanism per provider (Rust) | stable |

### colo/ — colo-host helpers ([overview](colo/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [colo-utils](colo/colo-utils/docs/PROJ-ARCH.md#overview) | Colo cluster dashboards + deploy relay | `cluster-*`/`colo-*` bash; systemd pull-based `helm-upgrade` relay | stable |

### database/ — DB CLIs ([overview](database/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [database-utils](database/database-utils/docs/PROJ-ARCH.md#overview) | Postgres/TimescaleDB/Valkey CLIs | liquibase-shell/-update, provision-db, tsdb-snapshot over k8-lib + `.infra-config.yaml` | stable |

### k8/ — build → push → deploy → operate pipeline ([overview](k8/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [k8-lib](k8/k8-lib/docs/PROJ-ARCH.md#overview) | Shared sourced-shell library | Config facade + output/Docker/Helm discovery all siblings load at runtime | mature |
| [docker-utils](k8/docker-utils/docs/PROJ-ARCH.md#overview) | Image build/push | BuildKit multi-arch, Infisical patch versioning | mature |
| [helm-utils](k8/helm-utils/docs/PROJ-ARCH.md#overview) | Tiered Helm upgrades | MD5 change detection, rollback, OCI publish | mature |
| [infra-utils](k8/infra-utils/docs/PROJ-ARCH.md#overview) | Deploy orchestration | `deploy-service` pipeline, `infra-config`, `infra-init` | mature |
| [secret-utils](k8/secret-utils/docs/PROJ-ARCH.md#overview) | Infisical secret sync | Rust `infisical` CLI/TUI + legacy bash; dc ↔ YAML ↔ Infisical | stable |
| [cluster-utils](k8/cluster-utils/docs/PROJ-ARCH.md#overview) | Cluster inspection | Seven `cluster-*` terminal dashboards (bash) | stable |
| [staging-utils](k8/staging-utils/docs/PROJ-ARCH.md#overview) | Staging lifecycle | Thin `staging-up/down/logs/status` wrappers over helm-upgrade/kubectl | beta |

### linux/ — Linux-only desktop apps ([overview](linux/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [queue-populator](linux/queue-populator/docs/PROJ-ARCH.md#overview) | Voice-memo → LLM queue + virtual mics | Wake-phrase capture, sherpa-onnx STT, PipeWire virtual sources (Rust); port of osx version | alpha |

### osx/ — macOS-only apps ([overview](osx/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [fstab](osx/fstab/docs/PROJ-ARCH.md#overview) | Linux-style `/etc/fstab` for macOS | Root LaunchDaemon mounting APFS/NTFS (ntfs-3g + FUSE-T) | beta |
| [queue-populator](osx/queue-populator/docs/PROJ-ARCH.md#overview) | Menu-bar voice-memo → LLM queue | Wake-phrase → Apple Speech → JSONL + 4 virtual mics (Swift 6) | stable |

### shell/ — shell & terminal utilities ([overview](shell/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [direnv-config](shell/direnv-config/docs/PROJ-ARCH.md#overview) | `dc` layered config/secret store | Layered YAML + SDKs bridging to the Infisical pipeline (Rust) | mature |
| [auto-sudo](shell/auto-sudo/docs/PROJ-ARCH.md#overview) | Rule-based sudo elevation | Rust+zsh rule engine | beta |
| [github-utils](shell/github-utils/docs/PROJ-ARCH.md#overview) | GitHub workflow helpers | Deepest-first bulk submodule commit/push; sole shell/ k8-lib consumer | stable |
| [make-repo](shell/make-repo/docs/PROJ-ARCH.md#overview) | Repo create/edit/fork | gh-wrapped `make-repo`/`fork-repo` | stable |
| [misc-git-utils](shell/misc-git-utils/docs/PROJ-ARCH.md#overview) | Git shortcuts + doc-pointers | Durable doc links (Rust) + bash shortcuts | beta |
| [quick-gist](shell/quick-gist/docs/PROJ-ARCH.md#overview) | GitHub gist CLI | gh gist wrapper with fzf | stable |
| [remote-tunnel](shell/remote-tunnel/docs/PROJ-ARCH.md#overview) | Reverse SSH / TCP tunnels | autossh reverse + flag-gated ngrok; installs to `~/bin` | beta |
| [repo-lock](shell/repo-lock/docs/PROJ-ARCH.md#overview) | Advisory session locks + commit mutex | Serializes concurrent agents on the shared index (Rust) | beta |
| [secret-bucket](shell/secret-bucket/docs/PROJ-ARCH.md#overview) | Agent-safe secret ops | Value-free list/diff/copy (Rust) | stable |
| [tabbing-on](shell/tabbing-on/docs/PROJ-ARCH.md#overview) | Terminal tab theming | Tab title/status/theme manager; Rust+sh with an Ink prototype | beta |
| [zellij](shell/zellij/docs/PROJ-ARCH.md#overview) | zellij workspace launchers | `zj-*` agent-workspace launchers + KDL layouts | beta |

### terraform/ — Terraform helpers ([overview](terraform/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [terraform-utils](terraform/terraform-utils/docs/PROJ-ARCH.md#overview) | Ad-hoc TF plan + state migration | `tf-plan-all` batch plan table, `migrate-tfstate` local → S3; not the Terragrunt stacks | stable |

### mk/ — shared Make harness ([overview](mk/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [subdirs.mk / check-subdirs.sh](mk/docs/PROJ-ARCH.md#overview) | Recursive subdir target dispatch | Capability-probed build/compile/test/install/clean fan-out; SUBDIRS consistency linter | mature |

### start-app-scaffold/ — project generator ([overview](start-app-scaffold/docs/PROJ-ARCH.md#overview))

| Tool | What | How / why | Maturity |
|------|------|-----------|----------|
| [start-app-scaffold](start-app-scaffold/docs/PROJ-ARCH.md#overview) | Scaffold portfolio projects from start-app template | Tarball hydration → `projects/<domain>/app` + Postgres/Valkey/Helm provisioning; LLM-assisted merges | stable |
