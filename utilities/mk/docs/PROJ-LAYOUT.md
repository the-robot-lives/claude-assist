# Project Layout

`utilities/mk` is a shared Make include package for recursive Makefile trees.
It provides a reusable `subdirs.mk` fragment that fans standard targets
(`build`, `compile`, `test`, `install`, `clean`) out to child directories, plus
a consistency checker that validates parent `SUBDIRS` declarations against the
Makefiles actually present on disk.

```
mk/
├── subdirs.mk              # Make include — recursive subdir target dispatch
├── check-subdirs.sh        # Consistency checker for SUBDIRS vs on-disk Makefiles
└── docs/                   # Documentation
    ├── PROJ-LAYOUT.md      #   This file — project structure map
    └── PROJ-LAYOUT.summary.md  # Companion quick-reference tree
```

## File Details

### `subdirs.mk`

Include fragment for parent Makefiles. Consumers set `SUBDIRS` (child
directories) and optionally override:

- `SUBDIR_TARGETS` — targets fanned out to children (default: `build compile test install clean`)
- `SUBDIR_PREFIX` — label prefix for progress output
- `SUBDIR_DESCRIPTION` — heading printed by the `help` target

Behavior: for each subdir with a `Makefile`, it probes (via `make -pn` +
`.PHONY` parsing) whether the child declares the requested target; skips it if
absent, and falls back from `build` to `compile` when only the latter exists.
Each subdir name is also a phony target that runs `make -C <dir>` directly.

### `check-subdirs.sh`

Standalone bash checker (`./check-subdirs.sh [root]`, defaults to cwd; the
`mk/` directory itself is excluded from scanning). Reports:

- `[MISSING-FROM-PARENT]` — a child has a Makefile but is absent from its parent's `SUBDIRS`
- `[MISSING-SUBDIRS]` — a parent Makefile with Makefile-bearing children lacks a `SUBDIRS` declaration
- `[MISSING-CHILD]` — `SUBDIRS` lists a directory with no Makefile

Exits non-zero on any inconsistency; suitable as a CI/pre-commit gate.

## Key Files Requiring Setup

None — the package is self-contained. Consumers only need
`include path/to/mk/subdirs.mk` and a `SUBDIRS :=` declaration in their
Makefile.
