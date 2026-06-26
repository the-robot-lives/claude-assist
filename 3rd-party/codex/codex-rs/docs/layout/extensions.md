# Extensions & Integrations Layout

## Overview

Extension crates provide optional, domain-specific capabilities that enhance Codex with integrations, connectors, and specialized features. Most extensions can be conditionally compiled.

## Extension Crates

### Extension Framework & APIs
```
ext/                         # Parent directory for all extensions
├── connector-*               # Connector implementations for various services
├── mcp-*                     # MCP protocol integrations
└── web-search/               # Web search capability
```

### Integration Categories

#### Connectors
Connector crates provide integrations with external systems:
- Data sources and APIs
- Cloud services
- Communication platforms
- Custom protocols

Use `ext/connector-<name>` pattern for consistency.

#### MCP Extensions
Model Context Protocol integrations enable Codex to expose capabilities via MCP:
- Tool definitions and handlers
- Resource endpoints
- Sampling implementations

Use `ext/mcp-<name>` pattern.

#### Feature Extensions
Standalone capability crates:
- `ext/web-search/` — Web search integration and result processing
- Additional extensions follow similar naming

## External Agent Integration

```
external-agent-migration/    # Configuration migration from external agents
external-agent-sessions/     # Session tracking and management
```

These crates handle compatibility with external agent systems and provide session persistence.

## Extension Patterns

### Discovery
Extensions are typically discovered via:
1. Feature flags in `Cargo.toml` (conditional compilation)
2. Plugin system in `core-plugins/`
3. Configuration in `config/`

### Configuration
Extensions read configuration from:
- `.envrc.dc` or environment variables (secrets)
- `config/extensions/*.toml` (structured config)
- Runtime command-line flags

### Testing
Extension tests should:
- Be isolated to their crate
- Mock external services when possible
- Use integration tests for end-to-end flows
- Reference mock clients (e.g., `cloud-tasks-mock-client/`)

## Adding a New Extension

1. Create `ext/my-feature/` directory with `Cargo.toml`
2. Add feature flag to root `Cargo.toml`: `my-feature = ["ext-my-feature/default"]`
3. Define public API in `ext-my-feature/src/lib.rs`
4. Add discovery code to `core-plugins/` if needed
5. Document in this file under appropriate category
6. Write tests in `ext-my-feature/tests/`

