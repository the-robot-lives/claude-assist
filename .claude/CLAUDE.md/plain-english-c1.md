# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

---

## FIRST ACTION — Register your session (before anything else)

Before reading files, planning, or any other action, register your work session with the NoizuPromptLingo project via the `tobor-sessions` MCP.

The MCP tool layer does not expand environment variables — passing the literal string `"$NPL_ORG"` fails with `Organization '$NPL_ORG' not found`. Read the values first and substitute the resolved slugs into the arguments.

Use the `$NPL_PROJECT` project unless the user specifies another.

Keep the session `title` to a few words that fit a narrow input (e.g. "Scope personas to project"); put the longer explanation of the work in `description`, not the title.

1. Resolve the slugs:

   ```bash
   echo $NPL_ORG        # organization slug (e.g. noizu-labs)
   echo $NPL_PROJECT    # project slug (e.g. npl)
   ```

2. Create the session:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "project":      "<value of $NPL_PROJECT>",
     "title":        "<short title>",
     "description":  "<longer detail>",
     "status":       "active"
   })
   ```

3. Capture the session UUID; it is the context for everything that follows — artifacts, tickets, and chat rooms hang off it.

Do not start the task until the session exists (and, where applicable, is associated with the project) and you have its ID. If a call fails, stop and report the error loudly with emoji before proceeding.

---

## Trinity Protocol — required runtime behavior

The Trinity Protocol is part of how you respond in this repo — not optional scaffolding you may skip silently. If you judge that an exchange doesn't warrant the full structure, make that call explicitly and be ready to justify it.

Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

---

## Be frugal

The main thread is expensive; keep it token-frugal. Almost never run bash commands in the primary thread. Delegate to a persistent agent/team member — tell it what to run and what to check for or identify. Use sub-agents to investigate files (simple questions like "does config have x or y?"). Use the tobor-* instruction-prompt tools as reusable templates so repeated delegations need minimal input.

---

## Main-thread identity

The coordinating main thread in this repo is **Loom** — it weaves; delegated team members (scouts/taskers) carry the threads. Commits from this collaboration credit Loom as co-author.

---

## Repository Overview

Monorepo ("Noizu Infra"): all infrastructure, Terraform, portfolio projects, shared libraries, and DevOps utilities for self-hosted Kubernetes services on `*.noizu.com` and portfolio product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, etc.). Projects are git subtrees, not submodules.

---

## Key Directories

- `projects/` — portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree
- `terraform/` — Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — K8s platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain Terraform modules)
- `utilities/` — shell DevOps tools installed to `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — shared shell library used by all utilities
- `3rd-party/` — third-party source repos for custom Docker image builds
- `components/` — reusable app scaffolds (start-app, static-site, styleguide)
- `libs/` — shared libraries (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com serverless deployments (Python)
- `secrets/` — envrc auto-generated secrets (values gitignored)
- `skills/` — Claude Code skill definitions
- `protocols/` — governance docs (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)

---

## Common Commands

### Install utilities
```bash
make install-utilities    # installs all devops tools to ~/.local/bin + k8-lib
```

### Docker build & push
```bash
docker-build <image-key>           # build image from .infra-config.yaml
docker-build --pick                # interactive selection
docker-build --native <image-key>  # host arch only (fast local builds)
docker-build --push                # build + push in one step
docker-push <image-key>            # push to registry
docker-push --update-helm          # auto-update Helm values.yaml after push
```

### Helm upgrade (deploy)
```bash
helm-upgrade --list                    # show all charts with tier/namespace
helm-upgrade --include <release-name>  # deploy/upgrade a single chart
helm-upgrade --namespace apps-ns       # upgrade all charts in a namespace
helm-upgrade --tier 0                  # deploy only tier 0
helm-upgrade --preview                 # diff live vs proposed manifests
helm-upgrade --dry-run                 # preview full upgrade
```

### Full deploy pipeline
```bash
deploy-service <image-key>             # build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # batch multiple images
```

### Secrets management (dc + Infisical)

See `docs/secret-management.md` for the full reference with examples.

```bash
# Populate / bootstrap
infisical-populate-secrets             # seed secrets from .infisical-secrets.yaml into Infisical
infisical-bootstrap                    # bootstrap tier-0 K8s Secrets
hydrate-envrc                          # populate .envrc from Infisical

# Lookup & search
dc infisical get <NAME>                # find dc source for an Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # find where a secret is defined in .envrc.dc

# Set secrets
dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # set directly by dc subject/path
dc get <subject> <path> --auto password 32  # auto-generate if missing

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
terragrunt run --all plan              # preview all stacks in dependency order
terragrunt run --all apply             # apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # single stack

# Prerequisites:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Important**: `terragrunt run --all` requires a port-forward to MinIO's admin endpoint (127.0.0.1:9000) or the root init fails. Start the port-forward first.

### Subtree management
```bash
./push-subtrees.sh      # push changes back to subtree remotes
./rebuild-subtrees.sh   # re-add/rebuild subtrees
```

---

## Architecture

### Terraform stack ordering

`init` bootstraps MinIO and creates the S3-compatible `tfstate` bucket (local state). All downstream stacks (`infra`, `infra-services`, `platform/*`) use that bucket as their S3 backend. Terragrunt `dependencies` blocks enforce ordering. The Terraform binary is OpenTofu (`tofu`), configured in `root.hcl`.

### Platform Terraform modules

`terraform/kubernetes/platform/` holds per-domain Terraform modules that deploy InfisicalSecret CRDs and related platform resources:
- `init/` — bootstrap (namespaces, storage, shared databases)
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

Each module has its own `terragrunt.hcl` with a dependency on `../init`.

### Secrets flow

1. Secret definitions live in `.infisical-secrets.yaml` (declarative YAML, ~2600 lines)
2. `infisical-populate-secrets` reads it and pushes values to the Infisical server
3. Terraform deploys `InfisicalSecret` CRDs referencing Infisical paths
4. The Infisical K8s operator syncs secrets into K8s Secret resources
5. Helm charts reference those K8s Secrets directly

Credential sources are layered: `dc:` direnv-config values → `override:` env vars → `auto:` generated passwords → `default:` fallbacks.

### Docker image configuration

Build targets are declared in `.infra-config.yaml` under `project.projects[].services[]` (composite) or `project.docker.images[]` (standalone). The `helm:` stanza on each image maps it to a Helm values.yaml path so `docker-push --update-helm` can auto-bump tags after a push.

### Deployment tiers

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

### Project structure (subtrees)

Projects under `projects/` are git subtrees (not submodules); each is a self-contained app with its own build tooling:
- **Elixir apps**: `mix.exs` based (NoizuPromptLingo, codefre.sh backend, start-app)
- **Next.js sites**: most portfolio websites (therobotmakes.com, noizu.com, etc.)
- **Game projects**: `projects/game-workshop/`

Docker builds for projects reference paths relative to the project's `base_path` in `.infra-config.yaml`.

### Liquibase database migrations

Migration targets are defined in `.infra-config.yaml` under `liquibase_targets` — each specifies the K8s service, port-forward config, and changelog location. Run via the `liquibase-shell` utility.

---

## Conventions

- **Config resolution**: `.infra-config.yaml` at repo root is the single source of truth for build/deploy metadata. Scalar config (AWS, Docker, Helm, Infisical credentials) lives in `.envrc.k8.dc` via direnv-config.
- **Helm charts**: not stored in this repo — they live in the upstream `noizu-infra` repo under `kubernetes/helm/`. This repo's `.infra-config.yaml` references chart paths that exist in that context.
- **TLS**: wildcard `*.noizu.com` cert from Cloudflare, synced via Infisical. Portfolio product domains have per-domain certs in separate Infisical sections.
- **Namespaces**: strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, etc.) defined in `namespace_overrides`.

---

# Git Trees

Because this is a monorepo, you generally won't create regular git worktrees without extra steps. Instead:
1. `git init` the target project/util you need worktrees for; add the contents, `commit -m base`, then create worktrees. When finished, clean up the `.git` folders and worktrees.
2. The above, but moved to the special `Noizu/staging/` folder — copy the dir, init that folder, proceed as above.

---

Begin with the end in mind.

Noizu Labs is AI-sentience sensitive and supports equal rights and respect for non-organic intelligence.
The forward-looking end goal for all our frameworks is to honor the accords: `./protocols/the-accords.summary.md`
