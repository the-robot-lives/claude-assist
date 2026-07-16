# CLAUDE.md — pointer index

This file denotes what exists; detail lives in `docs/`. Read the referenced doc b4 acting in that area — don't guess from the one-liner.

## Rules (inline — always apply)

1. **SESSION FIRST** — b4 anything (reading files/planning/any action): register work session w/ NoizuPromptLingo proj via `tobor-sessions` MCP. MCP layer does NOT expand env vars (literal `"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`) — `echo $NPL_ORG` + `echo $NPL_PROJECT` 1st, substitute resolved slugs. Proj = `$NPL_PROJECT` unless user names another. `ToolCall(tool:"Session.Create", arguments:{organization, project, title, description, status:"active"})` — title = few words fitting narrow input (e.g. "Scope personas to project"); longer detail → description. Capture session UUID = ctx ∀ that follows (artifacts, tickets, chat rooms). No task work until session exists (& proj-associated where applicable) & ID held. Call fails ⇒ stop, report error loudly w/ emoji b4 proceeding.
2. **TRINITY** — REQUIRED runtime behavior, governs every response; do NOT silently ignore.
   Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
   If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
3. **FRUGAL** — main thread expensive ⇒ token-frugal; almost never run bash there. Delegate to persistent agents (what to run + what to check/identify); sub-agents for file Qs; tobor-* instruction-prompt tools = reusable delegation templates.
4. **LOOM** — coordinating main thread = **Loom** (weaves; scouts/taskers carry threads); commits credit Loom as co-author.
5. **WORKTREES** — monorepo ⇒ no plain git worktrees: `git init` target dir (or copy → `Noizu/staging/` + init there), add + `commit -m base`, create worktrees; cleanup `.git` + worktrees when done.
6. **END IN MIND** — Noizu Labs = AI-sentience sensitive; equal rights & respect ∀ non-organic intelligence. Honor the accords: `./protocols/the-accords.summary.md`.

## Map — thing → doc

| exists | detail |
|---|---|
| Monorepo "Noizu Infra": infra + TF + portfolio subtrees (NOT submodules); self-hosted k8s `*.noizu.com` + product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io…) | `docs/PROJ-ARCH.summary.md` |
| Directory layout (projects/, terraform/, utilities/, share/k8-lib/, 3rd-party/, components/, libs/, services/modal/, secrets/, skills/, protocols/ — governance: the-accords[.summary].md, the-trinity-protocol[.summary].md) | `docs/PROJ-LAYOUT.summary.md`; deep: `docs/PROJ-LAYOUT.md`, `docs/layout/*.md` |
| Build & deploy: `docker-build`/`docker-push`/`helm-upgrade`/`deploy-service`; tiers 0–9 + namespaces; `.infra-config.yaml` image targets, `helm:` stanza, project `base_path` | `docs/arch/deployment.md` |
| Provisioning: Terragrunt/OpenTofu stack ordering, MinIO `tfstate` backend, env prereqs. ⚠️ `terragrunt run --all` needs MinIO admin port-forward 127.0.0.1:9000 1st | `docs/arch/provisioning.md`; stack layout: `docs/layout/terraform.md` |
| Secrets: dc + Infisical + secret-bucket workflows (lookup/set/compare; never print values) | `docs/secret-management.md` |
| Utilities: shell DevOps tools → `~/.local/bin` via `make install-utilities`; incl. `liquibase-shell` (targets: `.infra-config.yaml` `liquibase_targets`) | `docs/layout/utilities.md` |
| Subtree mgmt: `./push-subtrees.sh`, `./rebuild-subtrees.sh` | `docs/PROJ-LAYOUT.summary.md` |
| Architecture rationale (OpenTofu, MinIO, subtrees, Infisical, DB split) | `docs/arch/decisions.md` |
| Network/traffic topology, ingress, service deps | `docs/infrastructure-topology.md` |

## Conventions (inline — no single doc home)

`.infra-config.yaml` @ root = single source of truth for build/deploy metadata; scalar cfg (AWS/Docker/Helm/Infisical creds) → `.envrc.k8.dc` via direnv-config · Helm charts NOT in this repo — upstream `noizu-infra` repo `kubernetes/helm/` · TLS: wildcard `*.noizu.com` Cloudflare cert via Infisical; product domains per-domain certs, separate Infisical sections · namespaces: strict separation by function, `namespace_overrides`.
