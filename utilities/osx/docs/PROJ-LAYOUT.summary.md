# utilities/osx — Layout Summary

Grouping directory for standalone macOS-host utilities (no k8-lib / .infra-config.yaml).

```
osx/
├── Makefile              # Delegates to children via shared ../mk/subdirs.mk
├── fstab/                # Linux-style /etc/fstab LaunchDaemon (APFS/NTFS)
│   └── docs/             #   → fstab/docs/PROJ-LAYOUT.summary.md
├── queue-populator/      # Swift 6 menu bar voice-memo → LLM queue app + virtual mics
│   └── docs/             #   → queue-populator/docs/PROJ-LAYOUT.summary.md
└── docs/                 # PROJ-LAYOUT.md + this summary
```

Child docs: [fstab layout](../fstab/docs/PROJ-LAYOUT.summary.md) · [fstab arch](../fstab/docs/PROJ-ARCH.summary.md) · [queue-populator layout](../queue-populator/docs/PROJ-LAYOUT.summary.md) · [queue-populator arch](../queue-populator/docs/PROJ-ARCH.summary.md)
