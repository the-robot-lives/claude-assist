# Project Layout

`infra-utils` is a terminal utility package: infrastructure bootstrap helpers plus the
`deploy-service` release pipeline (build → push → values.yaml bump → helm upgrade).
Scripts install to `~/.local/bin` via `make install` and source shared helpers from
k8-lib (`~/.local/share/k8-lib`).

```
infra-utils/
├── bin/                          # Executable CLI tools (installed by Makefile)
│   ├── add-import-permissions    #   Sync terraformer-import IAM inline policy from canonical JSON
│   ├── deploy-one-off            #   TEMPLATE: ordered one-off helm deployment sequence (infra → stateful → apps)
│   ├── deploy-service            #   Build + multi-arch push, bump chart values.yaml tag, helm-upgrade owning release
│   ├── infra-config              #   Manage .infra-config.yaml resources (helm-dir, helm-alias, namespace, ...)
│   ├── infra-init                #   Dev setup & health check: terraform, repos, import, cleanup, state-upgrade, doctor
│   └── open-dashboard            #   Port-forward + open monitoring dashboards (goldilocks, kubecost, parca, signoz)
├── docs/                         # Documentation
│   ├── PROJ-ARCH.md              #   Architecture document
│   ├── PROJ-ARCH.summary.md      #   Architecture quick reference
│   ├── PROJ-LAYOUT.md            #   This file
│   ├── PROJ-LAYOUT.summary.md    #   Layout quick reference (keep in sync)
│   └── arch/
│       └── scripts.md            #   Detailed per-script architecture breakdown
├── .gitignore                    # Ignores editor swap files, .env, .envrc.local
├── Makefile                      # `make install` → copies bin/* to ~/.local/bin (INSTALL_DIR overridable)
└── README.md                     # Start here — install, config sources, project.yaml shapes, failure modes
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `Makefile` | Run `make install` (set `INSTALL_DIR` to override `~/.local/bin`) |
| repo-root `.infra-config.yaml` | Config source for `deploy-service` / `infra-config` (lives at infra root, not here) |
| `.envrc.k8.dc` | Scalar AWS/account config read by `infra-init` (lives at infra root, not here) |

## Notes

- All `bin/` scripts are bash; several source the optional k8-lib `assist.sh` for `--assist` AI help.
- `deploy-one-off` is a template — customize releases/namespaces/chart paths before use.
- Prerequisites: `terraform`, `kubectl`, `aws`, `git`, `docker-build`, `helm-upgrade`, `yq` (see README).
