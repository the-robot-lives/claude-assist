# Integrations

| Field | Value |
|-------|-------|
| **ID** | `integrations` |
| **Type** | Settings |
| **Category** | Integrations |
| **User Stories** | US-097, US-098 |

## Description

Connects the KB outward: git-backed versioning for off-machine history, and an MCP server so other agents and editors can query the KB directly.

## Key Components

- **Confirmation Prompt** — enable git remote / MCP server (US-097, US-098)

## Interactions

- Version the KB with git and push to a private remote for durable history and off-machine backup (US-097).
- Expose the KB via an MCP server so other agents and editor AI assistants can query it directly (US-098).

## Navigation

- Accessible from: Settings & Preferences or `/setup integrations`.
- Links to: KB Maintenance Console (git integration ties into backup).
