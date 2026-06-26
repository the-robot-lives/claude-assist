# Project Layout — Quick Reference

```
codex/
├── codex-rs/                   # Rust backend (core engine)
│   ├── core/                   # Core indexing logic
│   ├── protocol/               # Protocol definitions
│   ├── models-manager/         # LLM model management
│   ├── server/                 # API server
│   └── [other Rust crates]
├── codex-cli/                  # Node.js CLI
│   ├── bin/                    # Executables
│   ├── scripts/                # Utility scripts
│   └── package.json
├── sdk/                        # Multi-language SDKs
│   ├── python/                 # Python client
│   ├── python-runtime/         # Python runtime
│   └── typescript/             # TypeScript client
├── tools/                      # Development tools
│   ├── argument-comment-lint/  # Comment validator
│   └── buildifier              # Bazel formatter
├── bazel/                      # Build configuration
│   ├── modules/                # Bazel modules
│   ├── platforms/              # Platform defs
│   └── rules/                  # Custom rules
├── scripts/                    # Build & utility scripts
│   ├── codex_package/          # Packaging lib
│   ├── build_codex_package.py  # Package builder
│   ├── check_blob_size.py      # Size validator
│   └── [other utilities]
├── patches/                    # Dependency patches
│   └── [platform compatibility patches]
├── third_party/                # Vendored dependencies
│   ├── powershell/             # PowerShell
│   ├── v8/                     # V8 engine
│   ├── wezterm/                # Terminal
│   └── wine/                   # Windows compat
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          # Full project map
│   ├── PROJ-ARCH.md            # Architecture
│   ├── install.md              # Installation
│   ├── contributing.md         # Contributions
│   └── [other guides]
├── .github/                    # GitHub config
├── .devcontainer/              # Dev container
├── MODULE.bazel                # Bazel module
├── WORKSPACE.bazel             # Bazel workspace
└── README.md                   # Overview
```

## Component Reference

| Component | Location | Details |
|-----------|----------|---------|
| Main backend | `codex-rs/` | Rust core engine |
| CLI tool | `codex-cli/` | Node.js frontend |
| Python SDK | `sdk/python/` | Python integration |
| TypeScript SDK | `sdk/typescript/` | Node.js integration |
| Build system | `bazel/` + `scripts/` | Bazel config + utilities |
| Dev docs | `docs/` | Guides and references |

For detailed breakdowns, see the PROJ-LAYOUT.md files in each subdirectory.
