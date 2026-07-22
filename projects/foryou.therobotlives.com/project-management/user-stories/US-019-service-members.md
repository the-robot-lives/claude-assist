---
id: US-019
title: "Manage Service members and roles"
slug: service-members
personas: [P-003]
epic: "Services & Branding"
priority: should-have
complexity: medium
tags: [service, members, roles, pbac]
---

# US-019: Manage Service members and roles

## User Story

**As a** Service owner
**I want to** manage who has access to a Service and their roles
**So that** the right people can edit lists and view signups

## Acceptance Criteria

- **Given** I own a Service
  **When** I add a member or change their role
  **Then** their permissions update immediately
- **Given** a member's role limits them
  **When** they access the Service
  **Then** restricted actions are hidden or blocked
- **Given** I remove a member
  **When** the change applies
  **Then** they lose access to the Service

## Notes
Service membership inherits through the parent org/project (no new resource type).
