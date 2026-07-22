# Project Layout Summary — utilities/linux

Grouping directory for Linux-only desktop utilities; one child project.

```
linux/
├── Makefile                    # Delegates targets to SUBDIRS via ../mk/subdirs.mk
├── docs/                       # Grouping-level docs
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
└── queue-populator/            # Voice memo + PipeWire virtual-mic utility (Rust)
                                #   → ../queue-populator/docs/PROJ-LAYOUT.summary.md
                                #   → ../queue-populator/docs/PROJ-ARCH.summary.md
```
