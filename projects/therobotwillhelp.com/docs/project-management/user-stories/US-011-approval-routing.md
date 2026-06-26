---
id: US-011
title: "Auto-route approvals by role"
slug: approval-routing
personas: [P-002, P-006]
epic: "Workflow Builder"
priority: should-have
complexity: medium
tags: [routing, permissions, governance]
---

# US-011: Auto-route approvals by role

## User Story

**As an** operations manager  
**I want to** route outputs automatically by risk tier and role  
**So that** routine work stays fast while sensitive outputs get senior review.

## Acceptance Criteria

- **Given** a risk profile is assigned, **When** output completes, **Then** it is routed to the configured approver.
- **Given** routing is unavailable, **Then** the system pauses and surfaces a blocking action list.

