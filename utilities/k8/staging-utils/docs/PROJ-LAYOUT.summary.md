# Project Layout — Summary

Staging environment lifecycle tools (deploy/teardown/logs/status); bash, installs to `~/.local/bin`, config via k8-lib chain.

```
staging-utils/
├── bin/                        # staging-* executables
│   ├── staging-up              #   deploy (helm-upgrade --env stage)
│   ├── staging-down            #   uninstall staging Helm releases
│   ├── staging-logs            #   tail service logs
│   └── staging-status          #   pods/releases/KEDA/usage dashboard
├── docs/                       # PROJ-ARCH.md(+summary), PROJ-LAYOUT.md(+summary)
├── .gitignore                  # swap files, .env, .envrc.local
├── Makefile                    # make install
└── README.md                   # start here
```
