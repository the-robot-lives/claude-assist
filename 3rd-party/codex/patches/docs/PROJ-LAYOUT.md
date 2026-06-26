# Codex Dependency Patches — Project Layout

Collection of patch files for third-party dependencies used in Codex builds. These patches fix platform-specific issues and compatibility problems.

```
patches/
├── BUILD.bazel                 # Bazel configuration for patches
├── abseil_*.patch              # Abseil library patches
├── aws-lc-sys_*.patch          # AWS Libcrypto patches
├── bzip2_*.patch               # Bzip2 compression patches
├── llvm_*.patch                # LLVM compiler patches
├── ring_*.patch                # Ring cryptography patches
└── rules_*.patch               # Bazel rules patches
```

## Patch Categories

| Category | Patches |
|----------|---------|
| **Abseil** | Thread identity on Windows |
| **AWS-LC-SYS** | Memcmp checks, MSVC prebuilt, Windows fixes |
| **Bzip2** | Windows stack argument handling |
| **LLVM** | Custom libcxx, ARM64, MinGW compatibility |
| **Ring** | MSVC include directory fixes |
| **Bazel Rules** | Build script dependencies annotation |

These patches are applied during the build process for cross-platform compatibility.
