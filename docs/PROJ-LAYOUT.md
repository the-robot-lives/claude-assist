# Project Layout — Noizu Infra

Monorepo for all infrastructure, Terraform, portfolio projects, shared libraries, and DevOps
utilities behind the self-hosted Kubernetes cluster on `*.noizu.com` and portfolio product
domains. Projects under `projects/` and vendored sources under `3rd-party/` are managed as
**git subtrees** (not submodules).

Large directories are summarized here and expanded in [`layout/`](layout/). See also
[`PROJ-LAYOUT.summary.md`](PROJ-LAYOUT.summary.md) for the plain tree.

```
Noizu/
├── projects/                   # Portfolio products (49 subtrees) → layout/projects.md
│   ├── NoizuPromptLingo/       #   NPL — flagship Elixir+Next.js app (MCP servers, engine)
│   ├── therobotremembers/      #   TRR memory engine (Weaviate + pgvector)
│   └── …                       #   *.com sites, apps, planning-stage subtrees
│
├── terraform/                  # Terragrunt/OpenTofu stacks → layout/terraform.md
│   ├── kubernetes/             #   K8s platform: init, infra, infra-services, apps, platform/*
│   ├── cloudflare/             #   DNS + zones + TLS origin
│   ├── monitoring/  sendgrid/  namecheap/   # provider stacks
│   └── modules/                #   Shared modules
│
├── kubernetes/                 # Helm charts NOT tied to a single project
│   └── helm/apps/              #   remote-access (frps tunnel), tobornalp
│
├── utilities/                  # DevOps CLI tools → layout/utilities.md
│   ├── k8/                     #   docker-build, helm-upgrade, deploy-service, infisical-*
│   ├── shell/                  #   dc (direnv-config), tabbing-on, zellij, git helpers
│   └── database/  agent/  colo/  terraform/  start-app-scaffold/  osx/  linux/
│
├── components/                 # App scaffolds → layout/components-libs.md
│   ├── start-app/              #   Canonical Elixir+Next.js+Helm scaffold
│   ├── static-site/            #   Static-site scaffold + chart
│   └── styleguide/             #   @noizu/styleguide design-system generator
│
├── libs/                       # Shared libraries → layout/components-libs.md
│   ├── elixir-mcp/             #   Elixir MCP server+client library
│   ├── ai/elixir-weaviate/     #   Weaviate client for Elixir
│   └── scaffolding/core/       #   Core scaffolding library
│
├── 3rd-party/                  # Vendored source for custom Docker builds → layout/third-party.md
│                               #   codex, llama.cpp, n8n, penpot, directus, kroki, …
├── services/
│   └── modal/                  # Modal.com serverless deployments (Python)
├── share/
│   └── k8-lib/                 # Canonical shared shell library (used by utilities/)
├── skills/                     # Claude Code skill definitions → layout/skills.md
├── protocol/
│   └── the-accords.md          # Governance doc
├── infra/
│   └── docker-compose.yaml     # Local/aux docker-compose services
├── .local-backups/             # Timestamped backups of dc/secrets files (e.g. .envrc.dc)
├── docs/                       # This documentation (see below)
│
├── .infra-config.yaml          # ★ Single source of truth for build/deploy metadata
├── .infisical-secrets.yaml     # ★ Declarative secret definitions (~2600 lines, gitignored)
├── .envrc                      # ★ direnv entry — run `direnv allow`
├── .envrc.dc                   # ★ Canonical direnv-config (dc) secrets layer
├── .envrc.k8.dc  .envrc.tf     #   Scalar config for K8s / Terraform (dc-managed)
├── Makefile                    # `make install-utilities` and friends
├── push-subtrees.sh            # Push subtree changes back to remotes
├── rebuild-subtrees.sh         # Re-add / rebuild subtrees
├── migrate-platform-to-apps.sh # One-off: apps-ns → apps namespace migration
├── CLAUDE.md / AGENTS.md       # Agent instructions (session registration, conventions)
└── README.md                   # Start here
```

## docs/

```
docs/
├── PROJ-LAYOUT.md              # This file — navigable project map
├── PROJ-LAYOUT.summary.md      # Plain-tree companion (keep in sync)
├── layout/                     # Extracted per-directory detail
│   ├── projects.md   terraform.md   utilities.md
│   ├── third-party.md   components-libs.md   skills.md
├── secret-management.md        # dc + Infisical reference
├── infrastructure-topology.md  # Cluster topology
├── persistence-migration-runbook.md
├── new-start-app-setup.md      # Scaffolding a new project
├── github-integration-plan.md  npl-llm-guided-*.md  todo-oneuptime-fork.md
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.envrc` | Run `direnv allow` to load the environment |
| `.envrc.dc` | Canonical `dc` secrets layer — edit here (not `.envrc.dc.v2`, which is stale) |
| `.infisical-secrets.yaml` | Populate values, then `infisical-populate-secrets` (gitignored) |
| `.infra-config.yaml` | Build/deploy metadata — the source of truth for `docker-build` / `helm-upgrade` |
| `~/.kube/noizu/config` | `KUBE_CONFIG_PATH` for cluster access (see CLAUDE.md for `KUBE_*`/`AWS_*` vars) |
| tools | `make install-utilities` installs CLI tools to `~/.local/bin` + `k8-lib` |

## Conventions Recap

- **Namespaces**: strict separation by function (`data`, `apps`, `creative`, `ai`, `mail`, …).
  Use `apps`, never the retired `apps-ns`.
- **Helm charts**: portfolio charts live under `projects/*/helm`; shared platform charts live
  in the upstream `noizu-infra` repo (not all present in this checkout).
- **Secrets flow**: `.infisical-secrets.yaml` → Infisical → `InfisicalSecret` CRD → K8s Secret
  → Helm. Layered credential sources: `dc:` → `override:` → `auto:` → `default:`.
