# Extensions And Tools

Codex tool access is composed from built-in capabilities, MCP servers, plugin bundles, apps, skills, hooks, and optional extension crates. The model-visible surface is assembled by `codex-core`, while app-server exposes management and discovery APIs for clients.

## Layers

| Layer | Role |
| ----- | ---- |
| Built-in tools | Command execution, file edits, filesystem APIs, web search, image generation, and related first-party capabilities. |
| MCP | `codex-mcp` manages outbound MCP connections and tool calls; `mcp-server` exposes Codex functionality to MCP clients. |
| Plugins | Marketplace and local plugin metadata, bundled skills, hooks, apps, and MCP server declarations. |
| Skills | Markdown instruction packages loaded from configured roots and injected when selected or relevant. |
| Hooks | Event-driven local automation around session and tool lifecycle points. |
| Extensions | Optional crates under `ext/` that keep feature-specific behavior outside the core crate. |

## Approval And Exposure

Tool exposure is constrained by configuration, selected roots, plugin availability, sandbox policy, and approval settings. Core owns the final model-visible tool list and the approval templates used when a tool call needs confirmation. App-server provides the APIs clients use to list skills, hooks, plugins, apps, and experimental feature state.

## Execution Boundary

Process and filesystem side effects flow through execution abstractions rather than UI code. Local commands use the execution and sandboxing crates; remote environments use `exec-server` and `exec-server-protocol`. This keeps UI rendering, API transport, and process management separable.

