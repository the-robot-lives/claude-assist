# Codex Bazel Build System — Architecture

## Overview

Bazel build system configuration providing hermetic, reproducible builds across platforms (Linux, macOS, Windows). Codex uses Bazel modules, custom rules, and platform definitions to manage complex multi-language builds.

## Architecture

```
Source Code (Rust, Python, TypeScript, C++)
     ↓
Bazel Workspace (WORKSPACE.bazel)
     ↓
Modules (dependencies) → Platforms (targets) → Rules (build logic)
     ↓
Hermetic Build Environment
     ↓
Compiled Artifacts (binaries, libraries)
```

## Core Components

### Modules (`bazel/modules/`)

Declare and manage Bazel module dependencies via Module system:
- **bzlmod** configuration for dependency resolution
- Semantic versioning and lock files
- Transitive dependency management
- Platform-specific overrides

### Platforms (`bazel/platforms/`)

Define target platforms and architectures:
- CPU architectures (x86_64, ARM64, ARM)
- Operating systems (Linux, macOS, Windows)
- Compiler toolchains (GCC, Clang, MSVC)
- Feature combinations (with/without AVX2, NEON, etc.)

Allows same source to build for multiple targets.

### Rules (`bazel/rules/`)

Custom Bazel rules for specialized build tasks:
- **Codex-specific rules** (e.g., indexing, serialization)
- **Wrapper rules** (e.g., for Python packaging, Node.js bundling)
- **Test rules** (custom test harnesses)

## Build Strategy

| Phase | Purpose |
|-------|---------|
| **Configure** | Resolve dependencies, select toolchain |
| **Analyze** | Build target graph, validate constraints |
| **Build** | Compile and link in isolation |
| **Test** | Run test suite with clean environment |
| **Package** | Create distributable artifacts |

## Design Principles

1. **Hermeticity** — Builds are isolated; no external dependencies leak in
2. **Reproducibility** — Same source + config = identical artifacts
3. **Incrementality** — Only rebuild changed targets and dependents
4. **Parallelism** — Independent targets build concurrently
5. **Caching** — Reuse artifacts across builds and machines

## Multi-Platform Support

Bazel enables:
- Cross-compilation (build Linux binaries on macOS)
- Fat binaries (single build for multiple architectures)
- Platform-specific dependencies (Windows-only libraries)
- Toolchain selection per platform

Example: `bazel build //codex-rs:codex_indexer --platforms=@platforms//os:windows`

## Integration with Patches

Patches (from `patches/`) are applied during dependency resolution via:
- Bazel `patch` attribute in MODULE.bazel
- `--patch` flags for platform-specific fixes
- Ensures hermetic builds across all platforms

## Technology

- **Build System**: Bazel 7.x+
- **Module System**: bzlmod
- **Languages Supported**: Rust (via rules_rust), Python (via rules_python), TypeScript (via rules_nodejs), C++ (via rules_cc)
- **Remote Caching**: Compatible with BuildBuddy, Bazel remote cache
