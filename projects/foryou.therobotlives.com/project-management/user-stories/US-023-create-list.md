---
id: US-023
title: "Create a List within a Service"
slug: create-list
personas: [P-004, P-003]
epic: "Lists & Attributes"
priority: must-have
complexity: medium
tags: [list, create, service, item-3, item-4]
---

# US-023: Create a List within a Service

## User Story

**As a** Service editor
**I want to** create a named List within my Service
**So that** people have a specific collection to sign up to

## Acceptance Criteria

- **Given** I have edit access to a Service
  **When** I create a List with a name and slug
  **Then** the List is created under the Service and ready to declare attributes
- **Given** a List slug is already used in the Service
  **When** I submit
  **Then** I see a validation error and can choose another slug
- **Given** the List is created
  **When** I open it
  **Then** I can add attributes (US-026+) and preview its public form (US-035)

## Notes
MANDATORY — the "create a channel/List per project/service" ask (plan items 3/4).
One List per site is the migration vehicle.
