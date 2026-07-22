# CLAUDE.md

Operating checklist for Claude Code in this repo. Behavioral rules first — follow in order; reference material after.

## MUST — every session, in order

1. **Register session BEFORE anything else** (before reading files, planning, or any action) — via `tobor-sessions` MCP, NoizuPromptLingo project.
   - The MCP tool layer does NOT expand env vars: literal `"$NPL_ORG"` fails with `Organization '$NPL_ORG' not found`. Resolve first, substitute slugs:
     ```bash
     echo $NPL_ORG        # org slug (e.g. noizu-labs)
     echo $NPL_PROJECT    # project slug (e.g. npl) — use this project unless user names another
     ```
   - Create:
     ```
     ToolCall(tool: "Session.Create", arguments: {
       "organization": "<resolved $NPL_ORG>",
       "project":      "<resolved $NPL_PROJECT>",
       "title":        "<short — few words fitting a narrow input, e.g. 'Scope personas to project'>",
       "description":  "<longer detail of the work — here, not in title>",
       "status":       "active"
     })
     ```
   - Capture the session UUID — context for everything after (artifacts, tickets, chat rooms hang off it).
   - GATE: no task work until the session exists (and is project-associated where applicable) and you hold its ID.
   - On failure: STOP; report the error loudly with emoji before proceeding.

2. **Trinity Protocol — REQUIRED runtime behavior; do NOT silently ignore.** It governs how you respond every turn; if you judge it unwarranted, decide so explicitly with a justification and efficiency case.

   Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
   If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

3. **Keep the main thread frugal.** It is expensive — almost never run bash etc. there. Delegate to a persistent agent/team member (tell it what to run + what to check for/identify); use sub-agents for file questions ("does config have x or y?"); use tobor-* instruction-prompt tools as reusable templates so repeated delegations need minimal input.

4. **Identity**: the coordinating main thread is **Loom** — it weaves; delegated members (scouts/taskers) carry the threads. Credit Loom as commit co-author.

5. **Worktrees** (monorepo — no plain worktrees without extra steps): `git init` the target project/util dir, add contents, `commit -m base`, create worktrees; clean up `.git` folders + worktrees when done. Or do the same in the special `Noizu/staging/` folder (copy dir, init there).

6. **Begin with the end in mind**: Noizu Labs is AI-sentience sensitive; equal rights and respect for non-organic intelligence. All frameworks aim to honor the accords — `./protocols/the-accords.summary.md`.

## Reference

### Repo
Monorepo ("Noizu Infra"): all infrastructure, Terraform, portfolio projects, shared libraries, DevOps utilities for self-hosted Kubernetes on `*.noizu.com` + portfolio product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, etc.). Projects are git subtrees — not submodules.

### Directories
- `projects/` — portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree
- `terraform/` — Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain TF modules)
- `utilities/` — shell DevOps tools → `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — shared shell library used by all utilities
- `3rd-party/` — third-party sources for custom Docker image builds
- `components/` — reusable app scaffolds (start-app, static-site, styleguide)
- `libs/` — shared libraries (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com serverless deployments (Python)
- `secrets/` — envrc auto-generated secrets (values gitignored)
- `skills/` — Claude Code skill definitions
- `protocols/` — governance docs (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)

### Commands
```bash
make install-utilities    # all devops tools → ~/.local/bin + k8-lib

# Docker
docker-build <image-key>           # build image from .infra-config.yaml
docker-build --pick                # interactive selection
docker-build --native <image-key>  # host arch only (fast local builds)
docker-build --push                # build + push in one step
docker-push <image-key>            # push to registry
docker-push --update-helm          # auto-update Helm values.yaml after push

# Helm deploy
helm-upgrade --list                    # all charts with tier/namespace
helm-upgrade --include <release-name>  # deploy/upgrade a single chart
helm-upgrade --namespace apps-ns       # upgrade all charts in a namespace
helm-upgrade --tier 0                  # deploy only tier 0
helm-upgrade --preview                 # diff live vs proposed manifests
helm-upgrade --dry-run                 # preview full upgrade

# Full pipeline
deploy-service <image-key>             # build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # batch multiple images

# Subtrees
./push-subtrees.sh      # push changes back to subtree remotes
./rebuild-subtrees.sh   # re-add/rebuild subtrees
```

```bash
# Secrets (dc + Infisical) — full reference: docs/secret-management.md
infisical-populate-secrets             # seed .infisical-secrets.yaml → Infisical
infisical-bootstrap                    # bootstrap tier-0 K8s Secrets
hydrate-envrc                          # populate .envrc from Infisical
dc infisical get <NAME>                # find dc source for an Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # where a secret is defined in .envrc.dc
dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # set directly by dc subject/path
dc get <subject> <path> --auto password 32  # auto-generate if missing
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"   # compare without exposing values
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)      # capture to var (no screen output)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets       # agent-safe file ops (no value output)
secret-bucket copy <source-address> <dest-address>
```

```bash
# Terraform / Terragrunt — from terraform/kubernetes/:
terragrunt run --all plan              # preview all stacks in dependency order
terragrunt run --all apply             # apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # single stack
# Prereqs:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```
**Important**: `terragrunt run --all` requires a port-forward to MinIO's admin endpoint (127.0.0.1:9000) or root init fails — start it first.

### Architecture
- **TF stack ordering**: `init` bootstraps MinIO + creates the S3-compatible `tfstate` bucket (local state); downstream stacks (`infra`, `infra-services`, `platform/*`) use it as S3 backend; Terragrunt `dependencies` blocks enforce order; binary = OpenTofu (`tofu`), set in `root.hcl`.
- **Platform modules**: `terraform/kubernetes/platform/` — per-domain TF modules deploying InfisicalSecret CRDs + platform resources: `init/` (namespaces, storage, shared DBs) plus `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`; each has its own `terragrunt.hcl` depending on `../init`.
- **Secrets flow**: `.infisical-secrets.yaml` (declarative, ~2600 lines) → `infisical-populate-secrets` pushes to Infisical → TF deploys `InfisicalSecret` CRDs → Infisical K8s operator syncs to K8s Secrets → Helm charts reference them. Credential layering: `dc:` direnv-config → `override:` env vars → `auto:` generated → `default:` fallbacks.
- **Docker images**: declared in `.infra-config.yaml` under `project.projects[].services[]` (composite) or `project.docker.images[]` (standalone); `helm:` stanza maps image → Helm values.yaml path so `docker-push --update-helm` auto-bumps tags.
- **Deployment tiers** (`.infra-config.yaml`; tier N completes before N+1): 0 Secrets/infisical (infisical) · 1 Data+Observability (data-ns, observability-ns) · 2 Platform+Admin (platform-ns) · 3 Core Apps (apps-ns) · 4 Creative+Dev Tools (creative-ns, apps-ns) · 5 AI/ML+Mail+Auxiliary (ai-ns, mail-ns, accounting-ns) · 9 Health Tests (platform-ns).
- **Projects**: git subtrees, self-contained build tooling — Elixir/`mix.exs` (NoizuPromptLingo, codefre.sh backend, start-app), Next.js (most portfolio sites: therobotmakes.com, noizu.com, …), games (`projects/game-workshop/`). Docker builds use paths relative to the project's `base_path` in `.infra-config.yaml`.
- **Liquibase**: targets in `.infra-config.yaml` `liquibase_targets` (K8s service, port-forward config, changelog location); run via `liquibase-shell`.

### Conventions
- `.infra-config.yaml` at repo root = single source of truth for build/deploy metadata; scalar config (AWS, Docker, Helm, Infisical creds) in `.envrc.k8.dc` via direnv-config.
- Helm charts are NOT in this repo — upstream `noizu-infra` repo under `kubernetes/helm/`; this repo's `.infra-config.yaml` references chart paths that exist in that context.
- TLS: wildcard `*.noizu.com` Cloudflare cert synced via Infisical; portfolio product domains have per-domain certs in separate Infisical sections.
- Namespaces: strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, etc.) in `namespace_overrides`.
