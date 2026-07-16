# Project Layout — Summary (utilities/colo)

Grouping directory: child utility packages carry their own docs.

```
colo/
├── colo-utils/                 # Colo/k8s Bash utilities → colo-utils/docs/PROJ-LAYOUT.summary.md
│   ├── bin/                    #   cluster-* dashboards + colo-* helpers
│   ├── docs/                   #   child PROJ-LAYOUT / PROJ-ARCH
│   ├── colo-deploy-relay.service / .timer  # systemd units for deploy relay
│   ├── Makefile
│   └── README.md
├── docs/                       # PROJ-LAYOUT.md + this summary
└── Makefile                    # Subdir delegator (../mk/subdirs.mk)
```
