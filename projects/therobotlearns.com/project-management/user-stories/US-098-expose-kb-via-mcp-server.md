---
id: US-098
title: "Expose the KB via an MCP server"
slug: expose-kb-via-mcp-server
personas: [P-001, P-006]
epic: "Integrations"
priority: should-have
complexity: high
tags: [mcp, integration, api]
---

# US-098: Expose the KB via an MCP Server

## User Story

**As a** staff backend engineer who wants MCP/editor integration
**I want to** expose my KB via an MCP server
**So that** other agents and tools, like my editor's AI assistant, can query my knowledge base directly

## Acceptance Criteria

- **Given** the robot-learns environment is running
  **When** an MCP-compatible client connects
  **Then** it can discover and call tools to search and read KB articles and cards

- **Given** an external agent queries the KB via MCP
  **When** results are returned
  **Then** they respect the same structure and schemas as the underlying YAML/markdown data

- **Given** the MCP server is exposed
  **When** a query is made
  **Then** read access is provided without requiring the requester to have direct filesystem access to ~/.config/the-robot-learns-kb/

- **Given** the user wants to restrict access
  **When** configuring the MCP server
  **Then** it can be scoped to local-only (no network exposure) by default

## Notes
Also enables extension-API style consumption for tinkerers (P-006) building on top of the KB.
