# Project Architecture Summary

Codex is a multi-agent agentic runtime with pluggable LLM backends, model-controlled tool execution, and policy-enforced sandboxing. All surfaces (CLI, TUI, external clients) normalize to a shared **thread/turn/item** persistence model for consistent behavior.

## Five-Layer Architecture

| Layer | Components | Purpose |
| ----- | ---------- | ------- |
| **User Surfaces** | CLI (`exec`), TUI, external clients | Entry points with different UIs but consistent logic |
| **Transport & API** | app-server, JSON-RPC, protocols | IPC boundaries and versioned contracts |
| **Agent Runtime** | core, config, state, rollout | Reasoning, tool selection, model orchestration, persistence |
| **Tools & Extensions** | MCP, plugins, skills, sandbox policy | Capabilities, integrations, approval & safety |
| **System Abstraction** | model-provider, execution, filesystem | Unified interfaces for models and command execution |

## Thread/Turn/Item Model

All data persists in this three-level hierarchy:

- **Thread**: Conversation session (UUID, config, complete history)
- **Turn**: Single model interaction (user input → model output → tool execution)
- **Item**: Smallest unit (messages, reasoning, tool calls, outputs)

This model is **uniform across all surfaces**: CLI, TUI, app-server clients, and remote execution all speak the same abstraction, enabling resume, fork, and archive workflows without client-side reconstruction.

## Model Orchestration

Models are abstracted via `model-provider` (supports ChatGPT, Ollama, LM Studio, Claude API, etc.). Before each turn:
1. Core assembles context: system instructions, conversation history, available tools
2. Model is selected based on config and turn metadata
3. Request is streamed to model; responses streamed back
4. Tool calls are parsed, validated, approved, and executed
5. Results become turn items in persistent history

## Tool & Capability Composition

Tools come from multiple sources with exposure controlled by policy:
- **Built-in**: Command execution, file edits, filesystem ops
- **MCP servers**: Outbound connections managed by `codex-mcp`
- **Plugin system**: Bundled skills, hooks, apps, MCP declarations
- **Skills**: Markdown instruction packages injected by relevance
- **Extensions**: Optional crates for specialized integrations

Approval rules and sandbox policy constrain execution before tools run.

## Execution Layers

Command execution is isolated from UI code:

**Local Path**: `exec` crate with `sandboxing` policy enforcement (platform-specific: seccomp/caps on Linux, jobs on Windows)

**Remote Path**: `exec-server` + `exec-server-protocol` for distributed or hardened environments

Both produce consistent output that flows through turn/item model into history.

## Configuration & State

**Config** — Layered loaders: defaults → system → user → env vars → cloud (immutable per session)

**State** — Split by concern:
- Conversation: SQLite + rollout files (persistent, resume-capable)
- Session: In-memory runtime (model cache, turn state, transport)

## Multi-Surface Consistency

| Surface | Transport | UI | Use Case |
| ------- | --------- | -- | -------- |
| **CLI `exec`** | Direct core | JSONL/text | Batch, non-interactive |
| **TUI** | app-server-client (JSON-RPC) | Ratatui terminal | Interactive terminal |
| **App-Server** | JSON-RPC over WebSocket/Unix | External clients | Web, mobile, IDE clients |
| **Exec-Server** | Exec protocol | Remote execution | Distributed, sandboxed |

Each surface is **thin**; core logic stays in `codex-core`. This ensures behavior consistency regardless of entry point.

## Extension Points

- **Plugin System**: Bundles of skills, hooks, apps, and MCP declarations
- **Skills**: Markdown instruction packages injected by relevance
- **Hooks**: Event-driven automation (pre-execution, post-tool, session lifecycle)
- **Extensions**: Optional crates for feature-specific behavior (connectors, web search, etc.)

## Key Design Principles

1. **Crate-oriented boundaries** — Small crates; new concepts prefer specialization over growing core
2. **Protocol crates for contracts** — Clients depend on contracts, not runtime internals
3. **App-server as rich client boundary** — External clients get same lifecycle as first-party surfaces
4. **Shared thread model** — All surfaces speak thread/turn/item for resume, fork, archive
5. **Policy-controlled execution** — Commands isolated from UI with consistent enforcement across all backends
6. **Persistent sessions** — Conversations survive across client reconnections, enabling rich workflows

