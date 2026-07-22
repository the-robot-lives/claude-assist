# Project Layout

Codex — AI-powered code indexing and search platform. Full-stack implementation with Rust backend (codex-rs) and multi-language SDKs.

```
codex/
├── codex-rs/                   # Rust backend (core indexing engine) → see codex-rs/docs/
├── codex-cli/                  # CLI tool (Node.js) → [docs/codex-cli/PROJ-LAYOUT.md](../codex-cli/docs/PROJ-LAYOUT.md)
├── sdk/                        # Multi-language SDKs → [docs/sdk/PROJ-LAYOUT.md](../sdk/docs/PROJ-LAYOUT.md)
│   ├── python/                 # Python SDK
│   ├── python-runtime/         # Python runtime
│   └── typescript/             # TypeScript SDK
├── tools/                      # Development tools → [docs/tools/PROJ-LAYOUT.md](../tools/docs/PROJ-LAYOUT.md)
│   ├── argument-comment-lint/  # Argument documentation linter
│   └── buildifier              # Bazel formatter
├── bazel/                      # Build system config → [docs/bazel/PROJ-LAYOUT.md](../bazel/docs/PROJ-LAYOUT.md)
│   ├── modules/                # Reusable Bazel modules
│   ├── platforms/              # Platform definitions
│   └── rules/                  # Custom Bazel rules
├── scripts/                    # Build utilities → [docs/scripts/PROJ-LAYOUT.md](../scripts/docs/PROJ-LAYOUT.md)
│   ├── codex_package/          # Packaging utilities
│   └── [build/test/format scripts]
├── patches/                    # Dependency patches → [docs/patches/PROJ-LAYOUT.md](../patches/docs/PROJ-LAYOUT.md)
│   └── [platform-specific fixes for dependencies]
├── third_party/                # Vendored dependencies → [docs/third_party/PROJ-LAYOUT.md](../third_party/docs/PROJ-LAYOUT.md)
│   ├── powershell/             # PowerShell utilities
│   ├── v8/                     # V8 JavaScript engine
│   ├── wezterm/                # Terminal emulator
│   └── wine/                   # Windows compatibility layer
├── docs/                       # Project documentation
│   ├── PROJ-LAYOUT.md          # This file
│   ├── PROJ-LAYOUT.summary.md  # Quick reference
│   ├── PROJ-ARCH.md            # Architecture documentation
│   ├── contributing.md         # Contribution guidelines
│   ├── install.md              # Installation guide
│   ├── getting-started.md      # Quick start
│   └── [additional guides]
├── .github/                    # GitHub workflows and config
├── .devcontainer/              # Dev container configuration
├── .codex/                     # Codex-specific config
├── .vscode/                    # VS Code settings
├── MODULE.bazel                # Bazel module definition
├── WORKSPACE.bazel             # Bazel workspace config
└── README.md                   # Project overview (start here)
```

## Directory Purposes

| Directory | Type | Purpose |
|-----------|------|---------|
| **codex-rs** | Backend | Rust implementation of core indexing engine and APIs |
| **codex-cli** | Frontend | Command-line interface for Codex operations |
| **sdk** | SDK | Client libraries for Python and TypeScript integration |
| **tools** | Tools | Development utilities (linters, formatters, validators) |
| **bazel** | Build | Build system configuration and rules |
| **scripts** | Utilities | Build, packaging, and maintenance scripts |
| **patches** | Config | Patches for cross-platform dependency compatibility |
| **third_party** | Deps | Vendored external tools and libraries |
| **docs** | Docs | Project documentation and guides |

## Quick Links

- **Getting Started**: [install.md](install.md) → [getting-started.md](getting-started.md)
- **For Contributors**: [contributing.md](contributing.md)
- **For Integrators**: [docs/sdk/PROJ-LAYOUT.md](../sdk/docs/PROJ-LAYOUT.md)
- **For Operators**: [docs/bazel/PROJ-LAYOUT.md](../bazel/docs/PROJ-LAYOUT.md)
- **Architecture**: [PROJ-ARCH.md](PROJ-ARCH.md)

## Build & Development

- **Build System**: Bazel (see [bazel/](../bazel/docs/PROJ-LAYOUT.md))
- **Languages**: Rust (backend), Python/TypeScript (SDKs, scripts), Shell (utilities)
- **Workspace**: WORKSPACE.bazel at root

Detailed layouts for each major component are linked above.
