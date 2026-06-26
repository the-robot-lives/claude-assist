# Codex Third-Party Dependencies — Project Layout

External tools and libraries vendored as dependencies for Codex builds and runtime.

```
third_party/
├── powershell/                 # PowerShell utilities
│   └── ...PowerShell modules
├── v8/                         # V8 JavaScript engine
│   ├── ...V8 source/config
│   └── BUILD                   # Bazel build file
├── wezterm/                    # Wezterm terminal emulator
│   └── ...Wezterm dependencies
└── wine/                       # Wine Windows compatibility layer
    └── ...Wine configuration
```

## Third-Party Components

| Component | Purpose |
|-----------|---------|
| `powershell/` | PowerShell runtime and modules |
| `v8/` | V8 JavaScript engine (for embedded scripting) |
| `wezterm/` | Terminal emulator dependencies |
| `wine/` | Windows compatibility layer for cross-platform builds |
