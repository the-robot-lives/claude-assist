# Project Layout — utilities/linux

Grouping directory for Linux-only desktop utilities in the Noizu Infra
monorepo. It holds no source of its own — just a delegating Makefile and one
child utility project. Each child is self-documented; see the linked child
summaries rather than re-reading child internals here.

```
linux/
├── Makefile                    # Delegates build/compile/test/install/clean to SUBDIRS via ../mk/subdirs.mk
├── docs/                       # Docs for this grouping directory
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion (keep in sync)
└── queue-populator/            # Voice memo capture + PipeWire virtual-mic router (Rust)
    ├── src/                    #   Rust source (audio, stt, llm, queue, ui, coordinator)
    ├── config/                 #   PipeWire virtual-sources drop-in config
    ├── docs/                   #   Child docs (authoritative for internals)
    ├── Makefile                #   Linux-gated compile/test/install
    ├── install.sh              #   Build + install binary, config, models, autostart
    ├── uninstall.sh            #   Remove installed pieces
    ├── Cargo.toml              #   Crate manifest
    └── README.md               #   Child entry point
```

## Children

| Utility | What it is | Docs |
|---------|------------|------|
| `queue-populator/` | Voice-driven Ubuntu GNOME / PipeWire desktop utility: wake-phrase memo capture, on-device sherpa-onnx STT, LLM classification into JSONL queue entries, and voice-controlled routing of the live mic into four persistent PipeWire virtual sources. Rust port of `utilities/osx/queue-populator`. | [Layout](../queue-populator/docs/PROJ-LAYOUT.summary.md) · [Architecture](../queue-populator/docs/PROJ-ARCH.summary.md) |

## Makefile

The top-level `Makefile` sets `SUBDIRS := queue-populator` and includes the
shared `utilities/mk/subdirs.mk` harness, which fans out `build`, `compile`,
`test`, `install`, and `clean` to each subdir that defines the target
(falling back from `build` to `compile`, skipping subdirs without the
target). `make help` lists targets and subdirs.

Child Makefiles gate on Linux, so monorepo-wide builds skip these utilities
on other platforms.

## Notes

- No `.envrc`, `.env.example`, or other setup dotfiles exist at this level;
  configuration lives inside each child (see child docs).
- New Linux utilities should be added as a sibling folder and appended to
  `SUBDIRS` in the Makefile.
