# Project Layout — utilities/colo

Grouping directory for colo-server-related utility packages. Contains no tooling of
its own beyond a delegating Makefile; each child folder is a self-documented utility
package with its own `docs/` (see links below for child internals).

```
colo/
├── colo-utils/                 # Colo/k8s terminal utilities (Bash) → child docs below
│   ├── bin/                    #   cluster-* dashboards + colo-* helpers (10 tools)
│   ├── docs/                   #   PROJ-LAYOUT / PROJ-ARCH + arch/ details
│   ├── colo-deploy-relay.service  # systemd oneshot unit (colo server)
│   ├── colo-deploy-relay.timer    # 60s polling timer
│   ├── Makefile                #   installs colo-* tools to ~/.local/bin
│   └── README.md               #   tool reference and usage
├── docs/                       # This grouping directory's docs
│   ├── PROJ-LAYOUT.md          #   this file
│   └── PROJ-LAYOUT.summary.md  #   condensed tree for tools/agents
└── Makefile                    # Subdir delegator (SUBDIRS := colo-utils via ../mk/subdirs.mk)
```

## Children

| Package | Purpose | Docs |
|---------|---------|------|
| `colo-utils/` | Two Bash tool families: `cluster-*` dashboards (kubectl/helm/metrics-server terminal views of the noizu k8s cluster) and `colo-*` helpers for the noizu colo server (deploy relay, SSH tunnel LaunchDaemon, mirrored rsync). | [Layout](../colo-utils/docs/PROJ-LAYOUT.summary.md) · [Architecture](../colo-utils/docs/PROJ-ARCH.summary.md) |

## Notes

- The top-level `Makefile` only fans out to `SUBDIRS` (currently just `colo-utils`)
  via the shared `utilities/mk/subdirs.mk` include; add new colo packages by
  appending to `SUBDIRS`.
- `colo-utils/make install` installs only `colo-*` tools; `cluster-*` and the shared
  `k8-lib` come from the monorepo root's `make install-utilities`.
