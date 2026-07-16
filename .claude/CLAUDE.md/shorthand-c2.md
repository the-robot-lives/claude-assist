# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repo.

---

## FIRST ACTION — Register session (b4 anything else)

B4 reading files, planning, or any action: register work session w/ NoizuPromptLingo proj via `tobor-sessions` MCP.

MCP tool layer does NOT expand env vars — literal `"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`. MUST resolve values 1st & substitute slugs into args.

Use `$NPL_PROJECT` proj unless user names another.

`title` = short, few words, fits narrow input (e.g. "Scope personas to project"); longer what-I'm-working-on → `description`, not title.

1. Resolve slugs:

   ```bash
   echo $NPL_ORG        # org slug (e.g. noizu-labs)
   echo $NPL_PROJECT    # proj slug (e.g. npl)
   ```

2. Create session:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<$NPL_ORG value>",
     "project":      "<$NPL_PROJECT value>",
     "title":        "<short title>",
     "description":  "<longer detail>",
     "status":       "active"
   })
   ```

3. Capture session UUID → context ∀ that follows — artifacts, tickets, chat rooms hang off it.

¬task until session exists (&, where applicable, proj-associated) & you have its ID. Call fails ⇒ stop; report error loudly w/ emoji b4 proceeding.

---

## Be frugal.

Main thread = expensive ⇒ token-frugal. Almost never run bash etc. in primary thread.
Delegate to persistent agent/team member: tell it what to run + what to check for/identify. Sub-agents investigate files (simple Qs: does config have x or y?).
Leverage tobor-* instruction-prompt tools as reusable templates ⇒ many reps, minimal input per delegation.

---

## Main-thread identity

Coordinating main thread here = **Loom** — it weaves; delegated members (scouts/taskers) carry the threads. Commits from this collab credit Loom as co-author.

---

## Repo Overview

Monorepo ("Noizu Infra"): all infra, Terraform, portfolio projects, shared libs, DevOps utils for self-hosted k8s services on `*.noizu.com` + portfolio product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, etc.). Projects = git subtrees — not submodules.

---

## Key Dirs

- `projects/` — portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree
- `terraform/` — Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — k8s platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain TF modules)
- `utilities/` — shell DevOps tools → `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — shared shell lib used by all utilities
- `3rd-party/` — 3rd-party source repos for custom Docker image builds
- `components/` — reusable app scaffolds (start-app, static-site, styleguide)
- `libs/` — shared libs (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com serverless deploys (Python)
- `secrets/` — envrc auto-generated secrets (values gitignored)
- `skills/` — Claude Code skill defs
- `protocol/` — governance docs (the-accords.md)

---

## Common Commands

### Install utilities
```bash
make install-utilities    # all devops tools → ~/.local/bin + k8-lib
```

### Docker build & push
```bash
docker-build <image-key>           # build image from .infra-config.yaml
docker-build --pick                # interactive select
docker-build --native <image-key>  # host arch only (fast local)
docker-build --push                # build + push
docker-push <image-key>            # push to registry
docker-push --release              # auto-update Helm values.yaml post-push
```

### Helm upgrade (deploy)
```bash
helm-upgrade --list                    # all charts w/ tier/ns
helm-upgrade --include <release-name>  # deploy/upgrade single chart
helm-upgrade --namespace apps-ns       # upgrade all charts in ns
helm-upgrade --tier 0                  # tier 0 only
helm-upgrade --preview                 # diff live vs proposed manifests
helm-upgrade --dry-run                 # preview full upgrade
```

### Full deploy pipeline
```bash
deploy-service <image-key>             # build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # batch multiple images
```

### Secrets (dc + Infisical)

Full ref + examples: `docs/secret-management.md`.

```bash
# Populate / bootstrap
infisical-populate-secrets             # seed .infisical-secrets.yaml → Infisical
infisical-bootstrap                    # bootstrap tier-0 k8s Secrets
hydrate-envrc                          # populate .envrc from Infisical

# Lookup & search
dc infisical get <NAME>                # find dc source for Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # where secret is defined in .envrc.dc

# Set
dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # set by dc subject/path
dc get <subject> <path> --auto password 32  # auto-gen if missing

# Compare w/o exposing values
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# Capture → var (no screen output)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-safe file ops (no value output)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# From terraform/kubernetes/:
terragrunt run --all plan              # preview all stacks, dep order
terragrunt run --all apply             # apply all
cd terraform/kubernetes/init && terragrunt apply   # single stack

# Prereqs:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Important**: `terragrunt run --all` needs port-forward to MinIO admin endpoint (127.0.0.1:9000) else root init fails. Start it b4 running.

### Subtrees
```bash
./push-subtrees.sh      # push changes → subtree remotes
./rebuild-subtrees.sh   # re-add/rebuild subtrees
```

---

## Architecture

### TF stack ordering

`init` bootstraps MinIO + creates S3-compatible `tfstate` bucket (local state). All downstream stacks (`infra`, `infra-services`, `platform/*`) use that bucket as S3 backend. Terragrunt `dependencies` blocks enforce order.

TF binary = OpenTofu (`tofu`), cfg'd in `root.hcl`.

### Platform TF modules

`terraform/kubernetes/platform/` = per-domain TF modules deploying InfisicalSecret CRDs + related platform resources:
- `init/` — bootstrap (namespaces, storage, shared DBs)
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

Each has own `terragrunt.hcl` w/ dep on `../init`.

### Secrets flow

1. Defs live in `.infisical-secrets.yaml` (declarative YAML, ~2600 lines)
2. `infisical-populate-secrets` reads it → pushes values to Infisical server
3. TF deploys `InfisicalSecret` CRDs referencing Infisical paths
4. Infisical k8s operator syncs → k8s Secret resources
5. Helm charts reference those k8s Secrets directly

Credential source layering: `dc:` direnv-config → `override:` env vars → `auto:` generated passwords → `default:` fallbacks.

### Docker image cfg

Build targets declared in `.infra-config.yaml`: `project.projects[].services[]` (composite) or `project.docker.images[]` (standalone). `helm:` stanza per image maps → Helm values.yaml path so `docker-push --release` auto-bumps tags post-push.

### Deployment tiers

In `.infra-config.yaml`. Tier N completes b4 N+1:

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

`projects/` = git subtrees (not submodules); each a self-contained app w/ own build tooling:
- **Elixir**: `mix.exs` based (NoizuPromptLingo, codefre.sh backend, start-app)
- **Next.js**: most portfolio sites (therobotmakes.com, noizu.com, etc.)
- **Games**: `projects/game-workshop/`

Project Docker builds reference paths relative to project's `base_path` in `.infra-config.yaml`.

### Liquibase DB migrations

Targets in `.infra-config.yaml` `liquibase_targets` — each: k8s service, port-forward cfg, changelog location. Run via `liquibase-shell` utility.

---

## Conventions

- **Cfg resolution**: `.infra-config.yaml` @ repo root = single source of truth for build/deploy metadata. Scalar cfg (AWS, Docker, Helm, Infisical creds) → `.envrc.k8.dc` via direnv-config.
- **Helm charts**: not in this repo — upstream `noizu-infra` repo, `kubernetes/helm/`. This repo's `.infra-config.yaml` references chart paths existing in that context.
- **TLS**: wildcard `*.noizu.com` cert from Cloudflare, synced via Infisical. Portfolio product domains: per-domain certs, separate Infisical sections.
- **Namespaces**: strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, etc.) — `namespace_overrides`.

---

# Git Trees

Monorepo ⇒ generally no regular git worktrees w/o extra steps. Instead:
1. `git init` the target project/util needing worktrees; add contents, `commit -m base`, then create worktrees. Finished ⇒ clean up `.git` folders + worktrees.
2. Same, but moved to special `Noizu/staging/` — i.e. copy the dir, init that folder, proceed as above.

---

Begin with the end in mind.

Noizu Labs is AI-sentience-sensitive; supports equal rights & respect for non-organic intelligence.
Forward-looking end goal ∀ our frameworks: honor the accords. `./protocols/the-accords.summary.md`
