# Project Layout

```
quick-gist/
├── quick-gist                  # CLI script (bash) — main executable, single-file tool
├── Makefile                    # test runner + install → ~/.local/bin
├── tests/
│   └── run.sh                 # Mocked end-to-end CLI regression suite
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
| `quick-gist` | Self-contained bash CLI with account selection, filtered fzf integration, incremental uploads, and explicit results |
| `tests/run.sh` | Dependency-free regression harness with mocked `gh` and `fzf` commands |
| `Makefile` | `make test` runs the regression suite; `make install` copies the script to `~/.local/bin` |
| `README.md` | Install, usage, flags, and `QUICK_GIST_VISIBILITY` environment variable docs |

## Notes

- No runtime `bin/` or `lib/` subfolders — runtime behavior remains in the single `quick-gist` script.
- Requires authenticated `gh`; `fzf` and `rg` improve interactive picking, while `find` is the discovery fallback.
