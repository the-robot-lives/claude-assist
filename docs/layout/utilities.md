# utilities/ — DevOps CLI Tools

Shell/Rust tools installed to `~/.local/bin` via `make install-utilities` (root Makefile).
Each tool lives under a category dir as `<category>/<tool>/bin/<command>`. The shared shell
library `share/k8-lib` is the canonical lib consumed by these tools (edit there, not the
stale `utilities/k8/k8-lib`).

```
utilities/
├── Makefile                    # Aggregates install of all tools + k8-lib
├── push-3rd-party-images.sh    # Build & push all 3rd-party Docker images
│
├── k8/                         # Kubernetes / Docker / Helm / secrets tooling
│   ├── cluster-utils/bin/      #   cluster-status, cluster-nodes, cluster-resources,
│   │                           #   cluster-helm, cluster-layout, cluster-manticore, …
│   ├── docker-utils/bin/       #   docker-build, docker-push, docker-qemu11
│   ├── helm-utils/bin/         #   helm-upgrade, helm-rollback, helm-publish
│   ├── infra-utils/bin/        #   deploy-service, deploy-one-off, infra-config, infra-init,
│   │                           #   open-dashboard, add-import-permissions
│   ├── secret-utils/bin/       #   infisical-populate-secrets, infisical-bootstrap,
│   │                           #   hydrate-envrc, infisical-{audit,verify,set-secret,…}
│   ├── staging-utils/bin/      #   staging-up, staging-down, staging-status, staging-logs
│   └── k8-lib/                 #   (stale mirror — canonical copy is share/k8-lib)
│
├── shell/                      # Shell environment & git tooling
│   ├── direnv-config/bin/      #   dc-init, tabbing-on-step (the `dc` secrets layer)
│   ├── tabbing-on/shell-impl/  #   tabbing-* terminal theming/session tools (+ Rust mirror)
│   ├── zellij/bin/             #   zj-claude, zj-codex, zj-spawn, zj-tab, zj-panes
│   ├── github-utils/bin/       #   submodule-commit
│   ├── make-repo/bin/          #   make-repo, fork-repo
│   ├── misc-git-utils/bin/     #   gcap, gp, doc-pointers, submodule-{diff,pull}
│   ├── quick-gist/             #   quick-gist helper
│   ├── secret-bucket/          #   agent-safe secret file ops (no value output)
│   ├── remote-tunnel/          #   remote tunnel helper
│   └── auto-sudo/              #   auto-sudo helper
│
├── database/database-utils/bin/ # liquibase-shell, liquibase-update, provision-db,
│                                # tsdb-snapshot, pgbouncer/create-migrate-user SQL
├── agent/                       # AI-agent tooling
│   ├── claude-assist/          #   Full TS monorepo (api + cli) — conversation index/search
│   ├── media-tool/bin/         #   generate-media-prompt, media-eval-port-forward
│   ├── dangerously-safe/bin/   #   dangerously-safe wrapper
│   ├── mallm/                  #   multi-LLM helper
│   ├── run-claude/             #   run-claude launcher (e.g. run-claude-timescaledb)
│   └── skill-manage/           #   skill-manage — symlink skills/agents/commands + YAML catalog
│
├── colo/colo-utils/bin/        # Colo/cluster: colo-sync, colo-deploy-relay,
│                               # colo-local-model-link, cluster-* mirrors
├── terraform/terraform-utils/bin/ # migrate-tfstate, tf-plan-all
├── start-app-scaffold/bin/     # init-proj-scaffold, build-start-app-tarball
├── osx/                        # macOS: queue-populator (voice-memo app), fstab
├── linux/                      # Linux: queue-populator
└── mk/                         # Shared Makefile includes
```

## Key tools (most-used)

| Command | Purpose |
|---------|---------|
| `docker-build` / `docker-push` | Build/push images from `.infra-config.yaml` |
| `helm-upgrade` | Deploy/upgrade Helm charts (defaults to `--reset-values`) |
| `deploy-service <key>` | Full pipeline: build + push + chart bump + helm upgrade |
| `provision-db <target>` | Create DB/role/extensions on a live instance |
| `infisical-populate-secrets` | Seed Infisical from `.infisical-secrets.yaml` |
| `init-proj-scaffold` | Scaffold a new project from start-app (run in-repo copy) |
| `skill-manage` | Symlink-enable skills/agents/commands for Claude/Codex/Grok; audit + work-type catalog |
