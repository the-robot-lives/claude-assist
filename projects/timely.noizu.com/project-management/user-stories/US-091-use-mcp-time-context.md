---
id: US-091
title: "Use MCP time context"
slug: use-mcp-time-context
personas: [P-001, P-004]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-091: Use MCP time context

## User Story

**As a** integrated workflow user  
**I want to** allow agents to query approved time history and add annotations  
**So that** support AI-assisted work review

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
