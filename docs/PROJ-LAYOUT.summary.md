# Project Layout — Summary

Quick-reference tree for Noizu Infra. Kept in sync with [`PROJ-LAYOUT.md`](PROJ-LAYOUT.md).
`projects/` and `3rd-party/` entries are git subtrees.

```
Noizu/
├── projects/                 # 49 portfolio product subtrees (NPL, *.com sites, apps, planning)
├── terraform/                # Terragrunt/OpenTofu stacks
│   ├── kubernetes/           #   init, infra, infra-services, apps, platform/*, modules
│   ├── cloudflare/  monitoring/  namecheap/  sendgrid/
│   └── modules/
├── kubernetes/helm/apps/     # Cross-project Helm charts (remote-access, tobornalp)
├── utilities/                # DevOps CLI tools (installed via make install-utilities)
│   ├── k8/                   #   docker-build, helm-upgrade, deploy-service, infisical-*, cluster-*
│   ├── shell/                #   dc (direnv-config), tabbing-on, zellij, git helpers
│   ├── database/  agent/  colo/  terraform/  start-app-scaffold/  osx/  linux/  mk/
├── components/               # App scaffolds
│   ├── start-app/            #   Elixir + Next.js + Helm scaffold
│   ├── static-site/  styleguide/
├── libs/                     # Shared libraries
│   ├── elixir-mcp/  ai/elixir-weaviate/  scaffolding/core/
├── 3rd-party/                # Vendored source for custom Docker builds (18 repos)
├── services/modal/           # Modal.com serverless (Python)
├── share/k8-lib/             # Canonical shared shell library
├── skills/                   # Claude Code skill definitions
├── protocol/the-accords.md   # Governance doc
├── infra/docker-compose.yaml # Local/aux compose services
├── .local-backups/           # Timestamped dc/secrets backups
├── docs/                     # Documentation (PROJ-LAYOUT.md, layout/, secret-management.md, …)
│
├── .infra-config.yaml        # Build/deploy source of truth
├── .infisical-secrets.yaml   # Secret definitions (gitignored)
├── .envrc / .envrc.dc / .envrc.k8.dc / .envrc.tf   # direnv + dc secrets layers
├── Makefile                  # install-utilities, etc.
├── push-subtrees.sh / rebuild-subtrees.sh          # Subtree management
├── migrate-platform-to-apps.sh
├── CLAUDE.md / AGENTS.md / README.md
```

## Setup files

- `.envrc` → `direnv allow`
- `.envrc.dc` → canonical `dc` secrets layer (not `.envrc.dc.v2`)
- `.infisical-secrets.yaml` → `infisical-populate-secrets`
- `.infra-config.yaml` → build/deploy metadata
- `make install-utilities` → CLI tools to `~/.local/bin`
