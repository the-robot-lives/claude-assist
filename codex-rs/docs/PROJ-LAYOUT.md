# Project Layout

Codex is a multi-agent agentic system with a modular architecture. The project is organized into logical domains: a core agent engine, app-server for IPC, sandboxing for exec safety, model provider abstractions, extensions for integrations, and utilities.

## Directory Overview

### Core Agent Runtime
```
├── core/                     # Agent engine, prompt assembly, integration tests, and conversation history
├── core-api/                 # Boundary types and contracts for core engine
├── core-plugins/             # Plugin marketplace and plugin runtime system
├── core-skills/              # Built-in skill loading and discovery
├── features/                 # Feature flag definitions
```

### Application Server & IPC
```
├── app-server/               # JSON-RPC server implementation and handlers
├── app-server-client/        # Client library for connecting to app server
├── app-server-daemon/        # Background daemon process and management
├── app-server-protocol/      # Versioned wire protocol schemas and types
├── app-server-transport/     # Transport primitives (sockets, channels, streams)
├── app-server-test-client/   # Test client for validating server flows
```

### User Interfaces
```
├── cli/                      # Main `codex` command-line binary entry point
├── tui/                      # Terminal UI (Ratatui) with snapshot tests and interactive components
├── shell-command/            # Shell command parsing and display helpers
├── shell-escalation/         # Shell prompt/escalation patches and support
```

### Execution & Sandboxing
```
├── exec/                     # Command execution and result streaming
├── exec-server/              # Remote exec server (queries, result storage, tests)
├── exec-server-protocol/     # Exec server wire protocol
├── execpolicy/               # Policy parser and evaluator
├── execpolicy-legacy/        # Legacy policy implementation
├── bwrap/                    # Bubblewrap (Linux) sandbox integration
├── linux-sandbox/            # Linux sandbox implementation and tests
├── windows-sandbox-rs/       # Windows sandbox implementation
├── sandboxing/               # Shared sandboxing abstractions
├── process-hardening/        # Process hardening helpers (seccomp, caps, etc.)
```

### Language Models & Providers
```
├── model-provider/           # Provider abstraction layer (common interface for all LLMs)
├── model-provider-info/      # Provider metadata and model information
├── models-manager/           # Model manager CLI and bundled model data
├── chatgpt/                  # OpenAI ChatGPT provider integration
├── lmstudio/                 # LM Studio local model provider
├── ollama/                   # Ollama local provider integration
├── rmcp-client/              # RMCP client for model serving
```

### MCP (Model Context Protocol)
```
├── mcp-server/               # Codex MCP server implementation (tools, resources, sampling)
├── codex-mcp/                # MCP connection and tool management
├── backend-client/           # Client for backend service APIs
├── responses-api-proxy/      # Responses API proxy and npm package assets
```

### Integrations & Extensions → [layout/extensions.md](layout/extensions.md)
```
├── ext/                      # Extension crates: connectors, MCP integrations, web search, etc.
├── connectors/               # Connector domain types
├── external-agent-migration/ # External agent configuration migration
├── external-agent-sessions/  # External agent session tracking
```

### Data & State Management
```
├── state/                    # SQLite state storage and schema migrations
├── thread-store/             # Thread persistence crate
├── rollout/                  # Rollout persistence and replay support
├── rollout-trace/            # Rollout trace bundle handling
├── message-history/          # Conversation history storage
├── memories/                 # Memory read/write and migration crates
├── hooks/                    # Hook schema and execution
```

### Context & Reasoning
```
├── context-fragments/        # Context fragment types for runtime reasoning
├── prompts/                  # Prompt templates and rendering
├── response-debug-context/   # Response debugging context capture
├── agent-graph-store/        # Agent relationship graph storage
├── agent-identity/           # Agent identity model and helpers
├── feedback/                 # User feedback types
```

### Agent Runtime Infrastructure
```
├── code-mode-protocol/       # Code mode runtime and protocol
├── code-mode-host/           # Code mode host implementation
├── collaboration-mode-templates/ # Collaboration mode template resources
├── cloud-config/             # Cloud configuration and secrets
├── cloud-tasks-mock-client/  # Cloud task service mock client
├── cloud-tasks-client/       # Cloud task service client
├── login/                    # Authentication and login flows
├── keyring-store/            # Keyring-backed secret storage
├── secrets/                  # Secret handling and encoding
└── aws-auth/                 # AWS authentication helpers
```

### File & System Utilities
```
├── file-watcher/             # File change detection and watching
├── file-search/              # File search service
├── file-system/              # File-system abstraction layer
├── git-utils/                # Git helper library
├── terminal-detection/       # Terminal type and environment detection
├── install-context/          # Install method and package layout detection
└── codex-home/               # Home directory resolution for Codex
```

### General Utilities → [layout/utils.md](layout/utils.md)
```
├── utils/                    # Shared utility crates (async, encoding, etc.)
├── async-utils/              # Async utilities and helpers
├── ansi-escape/              # ANSI escape sequence parsing and rendering
├── arg0/                     # Process argv[0] manipulation helpers
├── apply-patch/              # Patch application binary and library
├── uds/                      # Unix-domain-socket utilities
├── stdio-to-uds/             # stdio to UDS bridge
├── network-proxy/            # Network proxy support
├── otel/                     # OpenTelemetry instrumentation
├── analytics/                # Analytics event types
└── realtime-webrtc/          # WebRTC real-time support
```

### Configuration & Tooling → [layout/root.md](layout/root.md) for full list
```
├── config/                   # Configuration loading, schema, and examples
├── protocol/                 # Shared protocol types across crates
├── codex-api/                # Public Codex API crate
├── codex-client/             # Codex client library
├── codex-experimental-api-macros/ # Experimental API proc macros
├── codex-backend-openapi-models/  # Generated OpenAPI models
├── v8-poc/                   # V8 JavaScript engine proof-of-concept
├── test-binary-support/      # Test-only binary support
└── thread-manager-sample/    # Example thread manager
```

### Build, Scripts & Documentation
```
├── docs/                     # Project documentation
│   ├── PROJ-LAYOUT.md        # This file — project structure guide
│   ├── PROJ-LAYOUT.summary.md # Compact tree for tools/agents
│   ├── layout/               # Detailed breakdowns by domain
│   │   ├── root.md           # Full root directory listing
│   │   ├── extensions.md     # Extension crate details
│   │   ├── utils.md          # Utility crate details
│   │   ├── config.md         # Configuration examples
│   │   └── ...
│   ├── bazel.md              # Bazel build system guide
│   ├── codex_mcp_interface.md # MCP interface reference
│   └── protocol_v1.md        # Legacy protocol reference
├── scripts/                  # Build, packaging, and maintenance scripts
├── vendor/                   # Vendored third-party source
└── .cargo/                   # Cargo configuration (features, patches)
```

### Repository Configuration
```
├── .config/                  # Repository-local tool configuration
├── .github/                  # GitHub workflows and automation
├── .gitignore                # Git ignore rules
├── Cargo.toml                # Rust workspace manifest
├── Cargo.lock                # Locked dependency graph
├── BUILD.bazel               # Root Bazel package
├── Makefile                  # Build targets (if present)
├── rust-toolchain.toml       # Pinned Rust toolchain version
├── rustfmt.toml              # Code formatting rules
├── clippy.toml               # Linter configuration
├── deny.toml                 # cargo-deny supply chain policy
├── default.nix               # Nix development environment
├── config.md                 # User-facing configuration guide
└── README.md                 # Project entry point
```

## Key Files Requiring Setup

| File | Action |
| ---- | ------ |
| `rust-toolchain.toml` | Rustup will automatically install the pinned toolchain on first build. |
| `default.nix` | Optional — use only if developing through the Nix workflow. |
| `Cargo.lock` | Commit this to ensure reproducible builds across environments. |
| `.cargo/config.toml` | Workspace-level Cargo settings (check-in rules, build flags). |

## Grouping Philosophy

- **Core** (agent engine, plugin system): Runtime reasoning and execution
- **I/O** (app-server, CLI, TUI): Entry points and user interfaces
- **Exec** (sandboxing, execution): Safe command execution with policy enforcement
- **Models** (provider abstractions): LLM integration and switching
- **Extensions** (integrations, connectors): Domain-specific capabilities
- **Infrastructure** (state, hooks, secrets, auth): Persistence and operational concerns
- **Utilities** (async, encoding, system): Shared foundational code

Detailed crate-by-crate breakdown: [layout/root.md](layout/root.md).

