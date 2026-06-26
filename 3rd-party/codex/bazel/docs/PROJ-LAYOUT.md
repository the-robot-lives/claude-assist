# Codex Bazel Build Configuration — Project Layout

Bazel build system configuration modules, platforms, and custom rules for Codex.

```
bazel/
├── modules/                    # Reusable Bazel modules
│   ├── ...module definitions
│   └── MODULE.bazel            # Module manifests
├── platforms/                  # Platform definitions
│   ├── ...platform configurations
│   └── BUILD                   # Platform build rules
└── rules/                      # Custom Bazel rules
    ├── ...custom rule definitions
    └── BUILD                   # Rule definitions
```

## Components

| Component | Purpose |
|-----------|---------|
| `modules/` | Reusable Bazel module definitions for package management |
| `platforms/` | Target platform and architecture configurations |
| `rules/` | Custom Bazel rules for specialized build tasks |
