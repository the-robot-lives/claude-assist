---
id: US-018
title: "Enforce role-based restrictions at runtime"
slug: role-based-restrictions
personas: [P-006, P-003]
epic: "Security and Governance"
priority: could-have
complexity: high
tags: [permissions, runtime, safety]
---

# US-018: Enforce role-based restrictions at runtime

## User Story

**As a** compliance steward  
**I want to** enforce role-based restrictions on tool execution at runtime  
**So that** policy is consistent during production work.

## Acceptance Criteria

- **Given** a robot attempts a restricted action, **When** policy checks run, **Then** action is denied and logged.
- **Given** denial occurs, **When** a reviewer inspects it, **Then** reason code and remediation suggestions are shown.

