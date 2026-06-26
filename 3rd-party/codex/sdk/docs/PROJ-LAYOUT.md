# Codex SDKs — Project Layout

Multi-language software development kits for integrating Codex functionality.

```
sdk/
├── python/                     # Python SDK
│   ├── src/                    # Source code
│   ├── tests/                  # Test suite
│   └── pyproject.toml          # Poetry configuration
├── python-runtime/             # Python runtime utilities
│   └── src/                    # Runtime source code
└── typescript/                 # TypeScript SDK
    ├── src/                    # Source code
    ├── tests/                  # Test suite
    └── package.json            # Node.js configuration
```

## SDK Components

| SDK | Purpose |
|-----|---------|
| `python/` | Python client library and utilities |
| `python-runtime/` | Python execution runtime components |
| `typescript/` | TypeScript/Node.js client library |
