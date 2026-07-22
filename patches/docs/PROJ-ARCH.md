# Codex Dependency Patches — Architecture

## Overview

Cross-platform compatibility patches for third-party dependencies. Codex builds on multiple platforms (Linux, macOS, Windows) and CPU architectures (x86_64, ARM), requiring patches to upstream libraries for compatibility.

## Architecture

```
Upstream Dependency (Abseil, LLVM, Ring, etc.)
     ↓
Bazel Fetch (via MODULE.bazel)
     ↓
Apply Patches (hermetic patch system)
     ↓
Patched Source → Compiled Library
```

## Patch Categories

### Abseil (Concurrency Library)

| Patch | Platform | Issue |
|-------|----------|-------|
| `abseil_windows_gnullvm_thread_identity.patch` | Windows GNU/Clang | Thread identity API missing in GnuLLVM |

### AWS Libcrypto (Cryptography)

| Patch | Platform | Issue |
|-------|----------|-------|
| `aws-lc-sys_memcmp_check.patch` | All | Build system compatibility |
| `aws-lc-sys_windows_msvc_memcmp_probe.patch` | Windows MSVC | Memory compare intrinsic detection |
| `aws-lc-sys_windows_msvc_prebuilt_nasm.patch` | Windows MSVC | NASM assembler path for prebuilts |

### Bzip2 (Compression)

| Patch | Platform | Issue |
|-------|----------|-------|
| `bzip2_windows_stack_args.patch` | Windows | Stack argument alignment for x86 |

### LLVM (Compiler Infrastructure)

| Patch | Platform | Issue |
|-------|----------|-------|
| `llvm_rusty_v8_custom_libcxx.patch` | All | libc++ linking for V8 engine |
| `llvm_windows_arm64_powl.patch` | Windows ARM64 | Floating-point library missing |
| `llvm_windows_mingw_compat.patch` | Windows MinGW | MinGW compatibility flags |

### Ring (Cryptography)

| Patch | Platform | Issue |
|-------|----------|-------|
| `ring_windows_msvc_include_dirs.patch` | Windows MSVC | Include directory paths for MSVC |

### Bazel Rules

| Patch | Component | Issue |
|-------|-----------|-------|
| `rules_cc_rusty_v8_custom_libcxx.patch` | C++ rules | libc++ support for V8 |
| `rules_rs_build_script_deps_annotation.patch` | Rust rules | Build script dependency tracking |

## Patch Application Strategy

1. **Declarative** — Patches declared in MODULE.bazel using `patch` attribute
2. **Hermetic** — Applied by Bazel during fetch phase; no manual patching
3. **Version-Specific** — Patches target specific dependency versions
4. **Tested** — Each patch validated in CI across all platforms

Example MODULE.bazel entry:
```python
bazel_dep(
    name = "abseil",
    version = "20230125.3",
    patches = ["//patches:abseil_windows_gnullvm_thread_identity.patch"],
)
```

## Patch Development Workflow

1. **Identify Issue** — Build fails on a platform; root cause is upstream
2. **Create Patch** — `diff -u original patched > name.patch`
3. **Validate** — Test patch application on affected platform
4. **Document** — Add entry to BUILD.bazel (tracked list)
5. **CI Validation** — Ensure patch works in multi-platform CI

## Patch Maintenance

| Task | Cadence | Owner |
|------|---------|-------|
| Track upstream fixes | Per-release | Maintainer |
| Remove obsolete patches | When dependency updates | Maintainer |
| Add platform-specific fixes | As needed | Contributor |

## Design Goals

- **Minimal Changes** — Patches are surgical; only fix what's necessary
- **Upstream-Focused** — Prioritize upstream fixes; patches are temporary
- **Clarity** — Patch intent documented in BUILD.bazel
- **Traceability** — Link patches to issues, PRs, upstream discussions

## BUILD.bazel Role

Central inventory file that:
- Lists all patches with comments
- Documents why each patch exists
- Cross-references upstream issues
- Tracks which patches can be removed when dependencies update
