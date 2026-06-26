---
id: US-003
title: "Build a workflow with handoff gates"
slug: build-workflow
personas: [P-002, P-003, P-004]
epic: "Workflow Builder"
priority: must-have
complexity: medium
tags: [builder, routing, handoffs]
---

# US-003: Build a workflow with handoff gates

## User Story

**As a** operations controller  
**I want to** build a multi-step workflow with explicit handoff points  
**So that** review and escalation happen at the right stage.

## Acceptance Criteria

- **Given** I define workflow steps, **When** I set a review gate, **Then** all downstream steps pause until approval.
- **Given** a handoff is configured, **When** a step completes, **Then** the next robot receives only the context needed for that stage.

## Notes
Allow both sequential and parallel flow modes in v1.

