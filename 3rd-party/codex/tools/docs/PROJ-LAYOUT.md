# Codex Tools — Project Layout

Development tools and utilities for building and validating Codex projects.

```
tools/
├── argument-comment-lint/      # Linter for argument documentation
│   ├── src/                    # Source code
│   ├── tests/                  # Test suite
│   └── BUILD                   # Bazel build file
└── buildifier                  # Bazel formatter/linter (executable)
```

## Tools

| Tool | Purpose |
|------|---------|
| `argument-comment-lint/` | Validates and lints argument comments in codebase |
| `buildifier` | Formats and lints Bazel BUILD files |
