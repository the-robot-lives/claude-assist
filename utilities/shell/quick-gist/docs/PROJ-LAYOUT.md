# Project Layout

```
quick-gist/
├── quick-gist                  # CLI script (bash) — main executable, single-file tool
├── Makefile                    # compile/test no-ops + install → ~/.local/bin
├── LICENSE.md                  # MIT license
├── README.md                   # Usage guide, options reference, install instructions
├── .gitignore                  # Editor swap files, .env, .envrc.local, .DS_Store
└── docs/                       # Project documentation
    ├── PROJ-ARCH.md            # Architecture notes
    ├── PROJ-ARCH.summary.md    # Architecture companion summary
    ├── PROJ-LAYOUT.md          # This file — project structure map
    └── PROJ-LAYOUT.summary.md  # Companion tree summary
```

## Key Files

| File | Purpose |
|------|---------|
| `quick-gist` | Single-file bash CLI wrapping `gh gist` with fzf integration — create gists from files/stdin, add to existing gists, list recent gists |
| `Makefile` | `make install` copies script to `~/.local/bin` (skips if already same file); `compile`/`test` are no-ops |
| `README.md` | Install, usage, flags, and `QUICK_GIST_VISIBILITY` environment variable docs |

## Notes

- No `bin/` or `lib/` subfolders — the entire tool is the single `quick-gist` script.
- Requires `gh` (authenticated); `fzf` optional for interactive picking.
