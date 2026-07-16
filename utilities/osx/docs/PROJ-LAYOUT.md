# Project Layout — utilities/osx

Grouping directory for macOS-host utilities in the Noizu monorepo. Each child is a
self-contained utility with its own build/install tooling and freshly maintained docs —
see the linked child summaries; internals are documented there, not here.

```
osx/
├── Makefile                    # Delegates to children via shared ../mk/subdirs.mk
│                               #   (SUBDIRS := fstab queue-populator)
├── fstab/                      # Linux-style /etc/fstab for macOS (LaunchDaemon)
│   ├── fstab-remount           #   Mount script (APFS / NTFS rw via ntfs-3g + FUSE-T)
│   ├── com.keithbrings.fstab-remount.plist  # LaunchDaemon plist
│   ├── osx-fstab.stub          #   Config template → /etc/osx-fstab
│   ├── Makefile                #   install / uninstall / status targets (sudo)
│   └── docs/                   #   → fstab/docs/PROJ-LAYOUT.summary.md
├── queue-populator/            # Menu bar voice-memo → LLM-classified queue app (Swift 6)
│   ├── Sources/                #   Swift app source (Audio, LLM, Queue, UI, ...)
│   ├── Driver/                 #   Virtual mic HAL driver build/uninstall scripts
│   ├── Package.swift           #   SwiftPM manifest
│   ├── install.sh              #   Install app + launchd LaunchAgent
│   └── docs/                   #   → queue-populator/docs/PROJ-LAYOUT.summary.md
└── docs/                       # This documentation
    ├── PROJ-LAYOUT.md
    └── PROJ-LAYOUT.summary.md
```

## Children

| Utility | What it is | Docs |
|---------|------------|------|
| `fstab/` | LaunchDaemon giving macOS Linux-style `/etc/fstab` behavior for APFS/NTFS volumes; installs to `/usr/local/bin` + `/Library/LaunchDaemons` via its own sudo Makefile | [Layout](../fstab/docs/PROJ-LAYOUT.summary.md) · [Arch](../fstab/docs/PROJ-ARCH.summary.md) |
| `queue-populator/` | macOS menu bar app (Swift 6 / AppKit / SwiftPM): wake-phrase voice memos → Apple Speech transcription → LLM classification → JSONL queue; also provides 4 BlackHole-derived virtual microphones | [Layout](../queue-populator/docs/PROJ-LAYOUT.summary.md) · [Arch](../queue-populator/docs/PROJ-ARCH.summary.md) |

## Notes

- Both children are **standalone macOS-host tools**: they do not use `k8-lib`,
  `make install-utilities`, or `.infra-config.yaml`; each installs via its own
  Makefile / install script.
- The top-level `Makefile` sets `SUBDIRS`, `SUBDIR_PREFIX := osx/`, and
  `SUBDIR_DESCRIPTION := macOS utilities`, then includes the shared
  `utilities/mk/subdirs.mk` fan-out; child Makefiles no-op on non-Darwin hosts
  where applicable.
- A separate PipeWire-based Linux port of queue-populator exists elsewhere in the repo.
