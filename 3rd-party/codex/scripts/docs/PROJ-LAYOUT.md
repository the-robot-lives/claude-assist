# Codex Build & Utility Scripts — Project Layout

Python and shell scripts for building, packaging, testing, and maintaining Codex projects.

```
scripts/
├── codex_package/              # Codex package utilities module
│   ├── __init__.py
│   ├── ...package utilities
│   └── BUILD                   # Bazel build file
├── install/                    # Installation scripts
├── .venv/                      # Python virtual environment (runtime)
├── asciicheck.py               # Verify ASCII-only text files
├── build_codex_package.py      # Build Codex packages
├── check_blob_size.py          # Validate blob size constraints
├── check-module-bazel-lock.sh  # Verify Bazel module lock state
├── debug-codex.sh              # Debug utility script
├── format.py                   # Code formatting utility
├── just-shell.py               # Shell helper functions
├── list-bazel-clippy-targets.sh    # List Rust clippy targets
└── list-bazel-release-targets.sh   # List release build targets
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `build_codex_package.py` | Build and package Codex distribution |
| `check_blob_size.py` | Validate binary artifact sizes |
| `check-module-bazel-lock.sh` | Verify Bazel dependency lock state |
| `format.py` | Apply code formatting rules |
| `asciicheck.py` | Enforce ASCII-only encoding in text files |
| `codex_package/` | Reusable Python package utilities |
