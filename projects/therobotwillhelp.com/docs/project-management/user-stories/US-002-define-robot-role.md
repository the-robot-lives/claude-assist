---
id: US-002
title: "Define a robot role with clear scope"
slug: define-robot-role
personas: [P-001, P-002, P-004]
epic: "Robot Management"
priority: must-have
complexity: low
tags: [roles, controls, permissions]
---

# US-002: Define a robot role with clear scope

## User Story

**As a** operations controller  
**I want to** define a robot with explicit job boundaries and tools  
**So that** I know what it is allowed to do without accidental scope creep.

## Acceptance Criteria

- **Given** role editor opens, **When** I set allowed tools and forbidden actions, **Then** the system blocks disallowed tool calls.
- **Given** scope is saved, **When** I view the role card, **Then** I can see permissions and escalation policy at a glance.

## Notes
This story underpins trust; role scope should be required before execution starts.

