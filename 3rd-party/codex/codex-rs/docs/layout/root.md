# Root Layout

```text
codex-rs/
├── .cargo/                   # Cargo configuration
├── .config/                  # Repository-local tool configuration
├── .github/                  # GitHub workflows and repository automation
├── agent-graph-store/        # Graph storage for agent relationships
├── agent-identity/           # Agent identity model and helpers
├── analytics/                # Analytics event types and reporting support
├── ansi-escape/              # ANSI escape parsing and rendering helpers
├── app-server/               # JSON-RPC app server implementation
├── app-server-client/        # Client library for the app server
├── app-server-daemon/        # Background app server process
├── app-server-protocol/      # Versioned app server wire protocol and schemas
├── app-server-test-client/   # Test client for app server flows
├── app-server-transport/     # App server transport primitives
├── apply-patch/              # Patch application binary and library
├── arg0/                     # Process argv[0] helpers
├── async-utils/              # Shared async utilities
├── aws-auth/                 # AWS authentication helpers
├── backend-client/           # Client for backend service APIs
├── bwrap/                    # Bubblewrap sandbox integration
├── chatgpt/                  # ChatGPT-specific integration code
├── cli/                      # Codex CLI binary crate
├── cloud-config/             # Cloud configuration support
├── cloud-tasks*/             # Cloud task service crates and mocks
├── code-mode*/               # Code mode runtime, host, and protocol crates
├── codex-api/                # Public Codex API crate
├── codex-backend-openapi-models/ # Generated backend OpenAPI models
├── codex-client/             # Codex client library
├── codex-experimental-api-macros/ # Experimental API proc macros
├── codex-home/               # Codex home directory resolution
├── codex-mcp/                # MCP connection and tool management
├── collaboration-mode-templates/ # Collaboration mode template resources
├── config/                   # Configuration loading, schema, and examples
├── connectors/               # Connector domain types
├── context-fragments/        # Context fragment types shared across runtime code
├── core/                     # Core agent engine, prompt assembly, and integration tests
├── core-api/                 # Core API boundary types
├── core-plugins/             # Plugin marketplace and plugin runtime support
├── core-skills/              # Built-in skill loading support
├── docs/                     # Project documentation
├── exec/                     # Command execution implementation
├── exec-server/              # Remote exec server implementation and tests
├── exec-server-protocol/     # Exec server wire protocol
├── execpolicy/               # Current exec policy parser and evaluator
├── execpolicy-legacy/        # Legacy exec policy implementation
├── ext/                      # Extension crates for connectors, MCP, skills, web search, and related features
├── external-agent-migration/ # External agent configuration migration logic
├── external-agent-sessions/  # External agent session tracking
├── features/                 # Feature flag definitions
├── feedback/                 # User feedback capture types
├── file-search/              # File search service and helpers
├── file-system/              # File-system abstraction helpers
├── file-watcher/             # File watching support
├── git-utils/                # Git helper library
├── hooks/                    # Hook schema and execution support
├── install-context/          # Install method and package layout detection
├── keyring-store/            # Keyring-backed secret storage
├── linux-sandbox/            # Linux sandbox implementation and tests
├── lmstudio/                 # LM Studio provider integration
├── login/                    # Login and authentication flows
├── mcp-server/               # Codex MCP server implementation
├── memories/                 # Memory read/write crates and migrations
├── message-history/          # Conversation history storage helpers
├── model-provider/           # Model provider abstraction layer
├── model-provider-info/      # Model provider metadata
├── models-manager/           # Model manager CLI and data files
├── network-proxy/            # Network proxy support
├── ollama/                   # Ollama provider integration
├── otel/                     # OpenTelemetry instrumentation support
├── plugin/                   # Plugin identity and metadata types
├── process-hardening/        # Process hardening helpers
├── prompts/                  # Prompt templates and rendering helpers
├── protocol/                 # Shared protocol types
├── realtime-webrtc/          # Realtime WebRTC support
├── response-debug-context/   # Response debugging context capture
├── responses-api-proxy/      # Responses API proxy and npm package assets
├── rmcp-client/              # RMCP client integration
├── rollout/                  # Rollout persistence and replay support
├── rollout-trace/            # Rollout trace bundle support
├── sandboxing/               # Shared sandboxing abstractions
├── scripts/                  # Repository scripts
├── secrets/                  # Secret handling crate
├── shell-command/            # Shell command parsing and display helpers
├── shell-escalation/         # Shell escalation support and patches
├── skills/                   # Skill discovery and configuration crate
├── state/                    # SQLite state storage and migrations
├── stdio-to-uds/             # stdio to Unix-domain-socket bridge
├── terminal-detection/       # Terminal environment detection
├── test-binary-support/      # Test-only binary support crate
├── thread-manager-sample/    # Sample thread manager implementation
├── thread-store/             # Thread persistence crate
├── tools/                    # Tool definitions and tests
├── tui/                      # Ratatui terminal UI
├── uds/                      # Unix-domain-socket utilities
├── utils/                    # Shared utility crates
├── v8-poc/                   # V8 proof-of-concept crate
├── vendor/                   # Vendored third-party source
├── windows-sandbox-rs/       # Windows sandbox implementation
├── .gitignore                # Git ignore rules
├── BUILD.bazel               # Root Bazel package definition
├── Cargo.toml                # Rust workspace manifest
├── Cargo.lock                # Locked Rust dependency graph
├── README.md                 # Short project entry point
├── clippy.toml               # Clippy lint configuration
├── config.md                 # User-facing configuration reference
├── default.nix               # Nix build entry point
├── deny.toml                 # cargo-deny policy
├── rust-toolchain.toml       # Pinned Rust toolchain
└── rustfmt.toml              # Rust formatting configuration
```
