---
id: US-013
title: "Create a Service"
slug: create-service
personas: [P-003, P-002]
epic: "Services & Branding"
priority: must-have
complexity: medium
tags: [service, create, tenant]
---

# US-013: Create a Service

## User Story

**As an** organization owner
**I want to** create a Service for a site or product
**So that** I have a tenant that owns lists and branding

## Acceptance Criteria

- **Given** I am in an organization
  **When** I submit a Service name and slug
  **Then** a Service is created under the org and I can configure it
- **Given** a slug is already used within the org
  **When** I submit
  **Then** I see a validation error and can pick another
- **Given** the Service is created
  **When** I open it
  **Then** I can proceed to create its first List (US-023)

## Notes
Service maps to the existing `projects` table (org → project/service).
