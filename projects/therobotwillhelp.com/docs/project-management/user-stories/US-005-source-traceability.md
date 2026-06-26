---
id: US-005
title: "Show source trace for each robot output"
slug: source-traceability
personas: [P-005, P-006]
epic: "Transparency"
priority: must-have
complexity: medium
tags: [traceability, audit, trust]
---

# US-005: Show source trace for each robot output

## User Story

**As a** compliance officer  
**I want to** see source snippets and tool call chain for each output  
**So that** I can verify correctness and policy compliance.

## Acceptance Criteria

- **Given** a completed message is visible, **When** I open trace mode, **Then** source docs, tool calls, and context snapshots are listed.
- **Given** a policy-sensitive workflow, **When** a source is blocked by retention policy, **Then** the system shows a clear reason and redaction state.

## Notes
Store traceability artifacts in immutable event logs when possible.

