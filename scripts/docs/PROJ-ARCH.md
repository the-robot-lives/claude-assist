# Codex Build & Utility Scripts — Architecture

## Overview

Automation scripts that support the build, testing, packaging, and distribution lifecycle. Includes Python utilities (build system integration) and shell scripts (tooling helpers).

## Architecture

```
Build Process / Developer Tasks
     ↓
Build Scripts | Utility Scripts | Format Scripts
     ↓
Codex Package Utilities (Python module)
     ↓
Bazel Integration | File System Operations
     ↓
Artifacts (executables, packages, reports)
```

## Script Categories

### Build & Packaging

| Script | Purpose |
|--------|---------|
| `build_codex_package.py` | Assemble distributable packages (binaries + SDKs) |
| `check_blob_size.py` | Validate binary sizes against thresholds |
| `codex_package/` | Python module for packaging utilities |

**Flow**: Extract artifacts → Bundle with SDKs → Verify sizes → Create distribution

### Quality & Validation

| Script | Purpose |
|--------|---------|
| `asciicheck.py` | Enforce ASCII-only encoding in text files |
| `check-module-bazel-lock.sh` | Verify Bazel MODULE.bazel lock consistency |
| `list-bazel-clippy-targets.sh` | Find Rust targets for clippy linting |

### Build Helpers

| Script | Purpose |
|--------|---------|
| `format.py` | Apply code formatting (prettier, yapf, rustfmt) |
| `just-shell.py` | Provide shell-like functions in Python |
| `list-bazel-release-targets.sh` | Enumerate release build targets |

## codex_package Module

Shared Python library providing:

```python
# Example usage
from codex_package import builder, validator, packager

artifacts = builder.build_release()
validator.check_sizes(artifacts)
package = packager.create_distribution(artifacts)
```

| Component | Responsibility |
|-----------|-----------------|
| **builder** | Invoke Bazel, collect artifacts |
| **validator** | Size checks, checksum validation |
| **packager** | Create archives, organize files |
| **manifest** | Track contents and metadata |

## Script Design

1. **Modularity** — Reusable utility functions extracted to `codex_package/`
2. **CLI Driven** — Scripts executable from command line; also importable as libraries
3. **Error Handling** — Clear error messages; non-zero exit codes on failure
4. **Logging** — Structured output (--verbose for details)
5. **Idempotency** — Safe to re-run; skips already-completed work

## Integration Points

- **Bazel Build** — Scripts invoke `bazel build/test` targets
- **CI/CD** — Run in GitHub Actions, pre-commit hooks
- **Docker Builds** — Called from Dockerfile during image construction
- **Release Pipeline** — Orchestrate version bumps, tagging, publishing

## Python Environment

- **Virtual Environment** — `.venv/` for isolated dependencies
- **Dependencies** — Listed in `pyproject.toml` (Poetry)
- **Python Version** — 3.9+
- **Testing** — pytest framework

## Shell Scripts

Simple shell utilities that:
- Query Bazel target graph
- Validate configuration state
- Prepare environment variables

No complex logic in shell; Python for computation-heavy tasks.
