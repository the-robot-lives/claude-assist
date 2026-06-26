---
id: US-012
title: "Connect Slack, Notion, and CRM connectors"
slug: integrations-connectors
personas: [P-003, P-004]
epic: "Integrations"
priority: should-have
complexity: high
tags: [integrations, tools, workflow]
---

# US-012: Connect Slack, Notion, and CRM connectors

## User Story

**As an** AI integrator  
**I want to** connect common tools used by operations teams  
**So that** robot output flows directly into existing processes.

## Acceptance Criteria

- **Given** a connector card exists, **When** credentials are added, **Then** the connector validates connectivity and writes a test payload.
- **Given** the connection is active, **When** a robot sends an update, **Then** the data lands in the configured destination.

