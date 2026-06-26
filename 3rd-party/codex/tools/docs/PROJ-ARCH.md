# Codex Tools — Architecture

## Overview

Developer tooling for building, validating, and maintaining Codex projects. Tools enforce code quality standards, validate configuration, and assist in build processes.

## Tool Architecture

```
Developer Workflow
     ↓
argument-comment-lint | buildifier | [other tools]
     ↓
Code Validation/Formatting
     ↓
CI/CD Pipeline Integration
```

## Core Tools

### argument-comment-lint

Validates argument documentation comments in code:

| Aspect | Details |
|--------|---------|
| **Purpose** | Ensure argument docs match actual parameters |
| **Input** | Source code files |
| **Output** | Lint results, violations report |
| **Integration** | Pre-commit hook, CI check |

- Detects:
  - Missing argument documentation
  - Documented arguments not in signature
  - Malformed comment syntax
- Language agnostic (works on any source)

### buildifier

Bazel BUILD file formatter and linter:

| Aspect | Details |
|--------|---------|
| **Purpose** | Consistent BUILD file formatting |
| **Input** | BUILD files |
| **Output** | Formatted/validated BUILD files |
| **Integration** | Pre-commit, CI pipeline |

- Enforces Buildifier style guide
- Sorts load statements and dependencies
- Detects common Bazel mistakes

## Tool Design Patterns

1. **Pluggable Architecture** — Each tool is independent; can be run separately or in sequence
2. **Exit Codes** — Standard POSIX exit codes (0 = success, 1 = validation failure, 2 = error)
3. **Output Formats** — Support text, JSON, and CI-friendly formats
4. **Idempotency** — Tools can fix issues or report only (where applicable)

## Integration Points

- **Pre-commit hooks** — Run before commits
- **CI/CD pipelines** — Gated checks before merge
- **IDE plugins** — Real-time feedback in editors
- **Build system** — Bazel rules that invoke tools

## Technology Stack

- **Languages**: Rust (buildifier), Python (argument-comment-lint)
- **Execution**: Standalone binaries (no runtime dependencies)
- **Configuration**: Command-line flags, config files
