# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## FIRST ACTION — Register your session (do this before anything else)

Before reading files, planning, or any other action, register your work session
with the NoizuPromptLingo project via the `tobor-sessions` MCP.

The MCP tool layer does NOT expand environment variables — passing the literal
string `"$NPL_ORG"` fails with `Organization '$NPL_ORG' not found`. You MUST read
the values first and substitute the resolved slugs into the arguments.

Use the `$NPL_PROJECT` project unless the user specifies an alternative project.

Keep the session `title` short — a few words that fit a narrow input (e.g.
"Scope personas to project"). Put the longer explanation of what you're working
on in the `description` field, not the title.

1. Resolve the slugs from the environment:

   ```bash
   echo $NPL_ORG        # organization slug (e.g. noizu-labs)
   echo $NPL_PROJECT    # project slug (e.g. npl)
   ```

2. Check whether the project exists:

   ```
   ToolCall(tool: "Project.Get", arguments: { "project": "<value of $NPL_PROJECT>" })
   ```

3a. **If the project exists** — create the session associated with it:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "project":      "<value of $NPL_PROJECT>",
     "title":        "<short title — a few words>",
     "description":  "<longer detail on what you're working on>",
     "status":       "active"
   })
   ```

3b. **If the project does NOT exist** — create the session WITHOUT a project,
    create the project, then associate it:

   ```
   # 1) session first (no project association yet)
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "title":        "<short title — a few words>",
     "description":  "<longer detail on what you're working on>",
     "status":       "active"
   })   # capture <session-uuid>

   # 2) create the project (owner_id defaults to the authenticated caller —
   #    only pass it to assign ownership to a different user)
   ToolCall(tool: "Project.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "slug":         "<value of $NPL_PROJECT>",
     "name":         "<project name>"
   })

   # 3) point the session at the new project
   ToolCall(tool: "Session.Update", arguments: {
     "session": "<session-uuid>",
     "project": "<value of $NPL_PROJECT>"
   })
   ```

4. Capture the session UUID and use it as the context for everything that
   follows — artifacts, tickets, and chat rooms hang off this session.

Do not proceed to the task until the session exists (and, where applicable, is
associated with the project) and you have its ID. If a call fails, stop and
report the error rather than continuing unregistered.

---

## Repository Overview

Monorepo ("Noizu Infra") containing all infrastructure, Terraform, portfolio projects, shared libraries, and DevOps utilities for self-hosted Kubernetes services on `*.noizu.com` and portfolio product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, etc.). Projects are managed as git subtrees — not submodules.

---

## Key Directories

- `projects/` — Portfolio product repos (Next.js sites, Elixir apps, game workshops). Each is a subtree.
- `terraform/` — Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — K8s platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain Terraform modules)
- `utilities/` — Shell-based DevOps tools installed to `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — Shared shell library consumed by all utilities
- `3rd-party/` — Third-party source repos for custom Docker image builds
- `components/` — Reusable app scaffolds (start-app, static-site, styleguide)
- `libs/` — Shared libraries (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com serverless deployments (Python)
- `secrets/` — Envrc auto-generated secrets (gitignored values)
- `skills/` — Claude Code skill definitions
- `protocol/` — Governance docs (the-accords.md)

---

## Common Commands

### Install Utilities
```bash
make install-utilities    # Installs all devops tools to ~/.local/bin + k8-lib
```

### Docker Build & Push
```bash
docker-build <image-key>           # Build specific image from .infra-config.yaml
docker-build --pick                # Interactive selection
docker-build --native <image-key>  # Host arch only (fast local builds)
docker-build --push                # Build + push in one step
docker-push <image-key>            # Push to registry
docker-push --update-helm          # Auto-update Helm values.yaml after push
```

### Helm Upgrade (Deploy)
```bash
helm-upgrade --list                    # Show all charts with tier/namespace
helm-upgrade --include <release-name>  # Deploy/upgrade a single chart
helm-upgrade --namespace apps-ns       # Upgrade all charts in a namespace
helm-upgrade --tier 0                  # Deploy only tier 0
helm-upgrade --preview                 # Diff live vs proposed manifests
helm-upgrade --dry-run                 # Preview full upgrade
```

### Full Deploy Pipeline
```bash
deploy-service <image-key>             # Build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # Preview
deploy-service backend frontend        # Batch multiple images
```

### Secrets Management (dc + Infisical)

See `docs/secret-management.md` for full reference with examples.

```bash
# Populate / bootstrap
infisical-populate-secrets             # Seed secrets from .infisical-secrets.yaml into Infisical
infisical-bootstrap                    # Bootstrap tier-0 K8s Secrets
hydrate-envrc                          # Populate .envrc from Infisical

# Lookup & search
dc infisical get <NAME>                # Find dc source for an Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # Search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # Find where a secret is defined in .envrc.dc

# Set secrets
dc infisical set <NAME> --value <V>    # Set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # Set directly by dc subject/path
dc get <subject> <path> --auto password 32  # Auto-generate if missing

# Compare without exposing values
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# Capture to variable (no screen output)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-safe file operations (no value output)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# From terraform/kubernetes/:
terragrunt run --all plan              # Preview all stacks in dependency order
terragrunt run --all apply             # Apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # Single stack

# Prerequisites:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Important**: `terragrunt run --all` requires a port-forward to MinIO's admin endpoint (127.0.0.1:9000) or the root init will fail. Start the port-forward before running.

### Subtree Management
```bash
./push-subtrees.sh      # Push changes back to subtree remotes
./rebuild-subtrees.sh   # Re-add/rebuild subtrees
```

---

## Architecture

### Terraform Stack Ordering

`init` bootstraps MinIO and creates the S3-compatible `tfstate` bucket (local state). All downstream stacks (`infra`, `infra-services`, `platform/*`) use that bucket as their S3 backend. Terragrunt `dependencies` blocks enforce ordering.

Uses OpenTofu (`tofu`) as the Terraform binary (configured in `root.hcl`).

### Platform Terraform Modules

`terraform/kubernetes/platform/` contains per-domain Terraform modules that deploy InfisicalSecret CRDs and related platform resources:
- `init/` — Bootstrap (namespaces, storage, shared databases)
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

Each module has its own `terragrunt.hcl` with dependencies on `../init`.

### Secrets Flow

1. Secret definitions live in `.infisical-secrets.yaml` (declarative YAML, ~2600 lines)
2. `infisical-populate-secrets` reads this file and pushes values to the Infisical server
3. Terraform deploys `InfisicalSecret` CRDs referencing Infisical paths
4. The Infisical K8s operator syncs secrets into K8s Secret resources
5. Helm charts reference those K8s Secrets directly

Credential sources are layered: `dc:` direnv-config values → `override:` env vars → `auto:` generated passwords → `default:` fallbacks.

### Docker Image Configuration

Build targets are declared in `.infra-config.yaml` under `project.projects[].services[]` (composite) or `project.docker.images[]` (standalone). The `helm:` stanza on each image maps it to a Helm values.yaml path so `docker-push --update-helm` can auto-bump tags after a push.

### Deployment Tiers

Defined in `.infra-config.yaml`. Tier N completes before N+1:

| Tier | Purpose | Namespace |
|------|---------|-----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Data + Observability | data-ns, observability-ns |
| 2 | Platform + Admin | platform-ns |
| 3 | Core Applications | apps-ns |
| 4 | Creative + Dev Tools | creative-ns, apps-ns |
| 5 | AI/ML + Mail + Auxiliary | ai-ns, mail-ns, accounting-ns |
| 9 | Health Tests | platform-ns |

### Project Structure (Subtrees)

Projects under `projects/` are git subtrees (not submodules). Each project is a self-contained app with its own build tooling:
- **Elixir apps**: `mix.exs` based (NoizuPromptLingo, codefre.sh backend, start-app)
- **Next.js sites**: Most portfolio websites (therobotmakes.com, noizu.com, etc.)
- **Game projects**: `projects/game-workshop/`

Docker builds for projects reference paths relative to the project's `base_path` in `.infra-config.yaml`.

### Liquibase Database Migrations

Database migration targets are defined in `.infra-config.yaml` under `liquibase_targets`. Each target specifies the K8s service, port-forward config, and changelog location. Run via the `liquibase-shell` utility.

---

## Conventions

- **Config resolution**: `.infra-config.yaml` at repo root is the single source of truth for build/deploy metadata. Scalar config (AWS, Docker, Helm, Infisical credentials) lives in `.envrc.k8.dc` via direnv-config.
- **Helm charts**: Not stored in this repo — they live in the upstream `noizu-infra` repo under `kubernetes/helm/`. This repo's `.infra-config.yaml` references chart paths that exist in that context.
- **TLS**: Wildcard `*.noizu.com` cert from Cloudflare is synced via Infisical. Portfolio product domains have per-domain TLS certs in separate Infisical sections.
- **Namespaces**: Strict namespace separation by function (data-ns, apps-ns, creative-ns, ai-ns, etc.) defined in `namespace_overrides`.


---

# Git Trees

Because this is a monorepo you generall will not want to create regular git worktrees with otu extra staps.
what you may do instead is: 
1. git init the target project/util etc. you need worktrees for. add the contents commit -m base and then create worktrees.
when finished cleanup the .git folders and worktrees.
2. the above but moved to the special Noizu/staging/ folder i.e. copy the dir, init that fodler, and proceed as above. 
