# bin/ — Sourced Shell Modules

Shell modules installed to `~/.local/share/k8-lib/bin` and sourced by the k8
devops commands. Two families: shared library/config modules, and `infra-init`
subcommand modules (`cmd_*` entry points).

```
bin/
├── common.sh               # Base include: config load, colours, output helpers
├── config.sh               # Configuration loader for k8-lib tools
├── config-resolver.sh      # Unified config resolution (env → dc → YAML → default)
├── project-registry.sh     # project.yaml registry loader/discovery
├── docker-config.sh        # Shared config + state mgmt for docker build/push workflow
├── docker-vsn.sh           # Resolve VSN_MAJOR/VSN_MINOR/BUILD_ENV from version or last build
├── helm-common.sh          # Shared definitions for helm-upgrade / helm-rollback
├── helm-publish-config.sh  # Chart discovery + state mgmt for Helm packaging / OCI publish
├── assist.sh               # AI-assisted help for k8 devops utilities
├── all.sh                  # infra-init all — runs repos → terraform → import → ...
├── repos.sh                # infra-init repos — hydrate git submodules
├── terraform.sh            # infra-init terraform — install/verify TF toolchain (OS+arch aware)
├── import.sh               # infra-init import — terraformer resource import
├── iam.sh                  # infra-init IAM import via aws CLI + terraform import (terraformer bypass)
├── state_upgrade.sh        # infra-init state-upgrade — migrate pre-0.13 provider addrs in tfstate
├── cleanup.sh              # infra-init cleanup — tidy terraform/production/imported artifacts
├── doctor.sh               # infra-init doctor — environment/prereq health checks
└── help.sh                 # infra-init help — usage text
```
