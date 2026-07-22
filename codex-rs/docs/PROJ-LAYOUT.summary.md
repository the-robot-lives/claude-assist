# Project Layout Summary

```text
codex-rs/
├── Core Agent Runtime
│   ├── core/                     # Agent engine, reasoning, integration tests
│   ├── core-api/                 # Boundary types and contracts
│   ├── core-plugins/             # Plugin system and marketplace
│   ├── core-skills/              # Built-in skill loading
│   └── features/                 # Feature flags
├── Application Server & IPC
│   ├── app-server/               # JSON-RPC server implementation
│   ├── app-server-client/        # Client library
│   ├── app-server-daemon/        # Background daemon
│   ├── app-server-protocol/      # Wire protocol schemas
│   ├── app-server-transport/     # Transport primitives
│   └── app-server-test-client/   # Test client
├── User Interfaces
│   ├── cli/                      # Command-line binary
│   ├── tui/                      # Terminal UI (Ratatui)
│   ├── shell-command/            # Command parsing
│   └── shell-escalation/         # Escalation support
├── Execution & Sandboxing
│   ├── exec/                     # Command execution
│   ├── exec-server/              # Remote exec server
│   ├── execpolicy/               # Policy enforcement
│   ├── bwrap/                    # Linux sandbox (bubblewrap)
│   ├── linux-sandbox/            # Linux sandbox impl
│   ├── windows-sandbox-rs/       # Windows sandbox impl
│   └── sandboxing/               # Shared abstractions
├── Language Models & Providers
│   ├── model-provider/           # Provider abstraction layer
│   ├── model-provider-info/      # Metadata and model info
│   ├── models-manager/           # Model manager CLI
│   ├── chatgpt/                  # OpenAI integration
│   ├── lmstudio/                 # LM Studio local provider
│   ├── ollama/                   # Ollama provider
│   └── rmcp-client/              # RMCP client
├── MCP (Model Context Protocol)
│   ├── mcp-server/               # Codex MCP server
│   ├── codex-mcp/                # MCP connections
│   ├── backend-client/           # Backend API client
│   └── responses-api-proxy/      # Responses API proxy
├── Data & State Management
│   ├── state/                    # SQLite state storage
│   ├── thread-store/             # Thread persistence
│   ├── rollout/                  # Rollout persistence
│   ├── message-history/          # Conversation history
│   ├── memories/                 # Memory management
│   └── hooks/                    # Hook system
├── Context & Reasoning
│   ├── context-fragments/        # Context types
│   ├── prompts/                  # Prompt templates
│   ├── agent-identity/           # Identity model
│   ├── feedback/                 # Feedback types
│   └── agent-graph-store/        # Relationship graphs
├── Infrastructure
│   ├── code-mode-protocol/       # Code mode support
│   ├── cloud-config/             # Cloud configuration
│   ├── login/                    # Auth and login
│   ├── keyring-store/            # Secret storage
│   ├── secrets/                  # Secret handling
│   └── aws-auth/                 # AWS auth helpers
├── File & System Utilities
│   ├── file-watcher/             # File watching
│   ├── file-search/              # File search service
│   ├── git-utils/                # Git helpers
│   ├── terminal-detection/       # Terminal detection
│   └── install-context/          # Install detection
├── General Utilities
│   ├── utils/                    # Shared utilities
│   ├── async-utils/              # Async helpers
│   ├── ansi-escape/              # ANSI parsing
│   ├── uds/                      # Unix sockets
│   ├── network-proxy/            # Network proxying
│   ├── otel/                     # Observability
│   └── analytics/                # Analytics events
├── Extensions & Integrations
│   ├── ext/                      # Extension modules
│   ├── connectors/               # Connector types
│   └── external-agent-*/         # External agent support
├── Build, Scripts & Documentation
│   ├── docs/                     # Documentation
│   │   ├── PROJ-LAYOUT.md        # Structure guide
│   │   ├── layout/               # Detailed breakdowns
│   │   ├── bazel.md              # Bazel guide
│   │   └── codex_mcp_interface.md # MCP reference
│   ├── scripts/                  # Build scripts
│   ├── vendor/                   # Vendored source
│   └── .cargo/                   # Cargo config
├── Repository Configuration
│   ├── .config/                  # Tool config
│   ├── .github/                  # GitHub workflows
│   ├── .gitignore
│   ├── Cargo.toml                # Workspace manifest
│   ├── Cargo.lock                # Locked dependencies
│   ├── BUILD.bazel               # Bazel root
│   ├── rust-toolchain.toml       # Rust version
│   ├── rustfmt.toml              # Format config
│   ├── clippy.toml               # Lint config
│   ├── deny.toml                 # Dependency policy
│   ├── default.nix               # Nix environment
│   └── README.md                 # Project entry
```

