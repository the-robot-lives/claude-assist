# Project Layout — Summary

```
infra-utils/
├── bin/                          # CLI tools → ~/.local/bin
│   ├── add-import-permissions    # IAM policy sync for Terraformer imports
│   ├── deploy-one-off            # Template ordered helm deploy
│   ├── deploy-service            # Build → push → values bump → helm upgrade
│   ├── infra-config              # Manage .infra-config.yaml resources
│   ├── infra-init                # Setup/health: terraform, repos, import, doctor
│   └── open-dashboard            # Port-forward monitoring dashboards
├── docs/
│   ├── PROJ-ARCH.md
│   ├── PROJ-ARCH.summary.md
│   ├── PROJ-LAYOUT.md
│   ├── PROJ-LAYOUT.summary.md
│   └── arch/scripts.md           # Per-script details
├── .gitignore
├── Makefile                      # make install
└── README.md                     # Start here
```
