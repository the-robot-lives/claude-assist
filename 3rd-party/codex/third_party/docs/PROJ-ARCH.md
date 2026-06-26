# Codex Third-Party Dependencies — Architecture

## Overview

Vendored external tools and libraries used by Codex during build and runtime. These are specialized tools that don't fit the standard Bazel dependency model and require custom integration.

## Architecture

```
Codex Build & Runtime
     ↓
Tool Requirements (PowerShell, V8, Terminal, Compat)
     ↓
third_party/ (Vendored distributions)
     ↓
Build Artifacts | Runtime Executables
```

## Vendored Components

### V8 (JavaScript Engine)

| Aspect | Details |
|--------|---------|
| **Purpose** | Embedded JavaScript runtime for Codex functionality |
| **Use Case** | Dynamic query evaluation, custom indexing logic |
| **Location** | `third_party/v8/` |
| **Integration** | Compiled into codex-rs via `rules_rust` + custom FFI bindings |

- Custom build configuration for minimal footprint
- Platform-specific optimizations (x86_64, ARM64)
- Static linking to codex-rs binary

### PowerShell

| Aspect | Details |
|--------|---------|
| **Purpose** | Windows automation and system administration |
| **Use Case** | Cross-platform build scripts on Windows |
| **Location** | `third_party/powershell/` |
| **Integration** | Bundled in Windows releases for script execution |

- Enables consistent scripting across platforms
- No dependency on system PowerShell version

### Wezterm (Terminal Emulator)

| Aspect | Details |
|--------|---------|
| **Purpose** | Terminal emulation library |
| **Use Case** | TUI (text user interface) rendering and escape sequence handling |
| **Location** | `third_party/wezterm/` |
| **Integration** | Linked into CLI for rich terminal output |

- Cross-platform terminal capability detection
- Unicode and color support
- Windows, macOS, Linux compatibility

### Wine (Windows Compatibility Layer)

| Aspect | Details |
|--------|---------|
| **Purpose** | Run Windows binaries on non-Windows platforms |
| **Use Case** | CI/testing Windows-only tools on Linux agents |
| **Location** | `third_party/wine/` |
| **Integration** | Optional runtime for development/testing |

- Allows single CI pipeline to test Windows binaries
- Development use only (not shipped to users)

## Dependency Management

| Tool | Versioning | Updates | Maintenance |
|------|-----------|---------|-------------|
| V8 | Semantic (major.minor.patch) | Quarterly | High (security updates) |
| PowerShell | Semantic | Monthly | Medium |
| Wezterm | Semantic | Monthly | Low |
| Wine | Semantic | Infrequent | Low (dev-only) |

## Integration Patterns

### Bazel Integration

```python
# MODULE.bazel example
local_path_override(
    module_name = "v8",
    path = "third_party/v8",
)

# BUILD file usage
cc_library(
    name = "v8_engine",
    deps = ["@v8//:v8"],
)
```

### Binary Bundling

Windows releases include:
```
codex-<version>-windows/
├── bin/
│   ├── codex.exe
│   ├── pwsh.exe (PowerShell)
│   └── wezterm.dll
└── README
```

### Runtime Library Linking

```rust
// codex-rs/src/lib.rs
extern "C" {
    fn V8_Initialize();
    fn V8_ExecuteScript(script: *const c_char);
}
```

## Design Goals

1. **Isolation** — Vendored code doesn't affect external package managers
2. **Reproducibility** — Exact versions pinned for hermetic builds
3. **Minimal Footprint** — Only include necessary files (strip unused components)
4. **Cross-Platform** — Support Linux, macOS, Windows (x86_64, ARM)
5. **Security** — Regular updates to patch vulnerabilities

## Update Workflow

1. **Check for Updates** — Monitor upstream releases
2. **Update Module** — Download and integrate new version
3. **Test Integration** — Ensure Bazel builds correctly
4. **Update Documentation** — Note version and changelog
5. **CI Validation** — Test across all platforms
6. **Release** — Include updated dependency in next Codex release

## Storage

Where applicable, third-party tools are:
- Downloaded during Bazel fetch phase (no storage bloat in repo)
- Or committed directly for small, critical components
- Version pinned in MODULE.bazel or lockfiles
