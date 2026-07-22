---
id: US-006
title: "Create an organization"
slug: create-organization
personas: [P-002]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, org, create-org, item-2]
---

# US-006: Create an organization

## User Story

**As an** orgless new user
**I want to** create an organization with a slug and name
**So that** I can own a Service and start collecting signups

## Acceptance Criteria

- **Given** I am on `/app/orgs/new`
  **When** I submit a valid organization name and slug
  **Then** the organization is created with me as its owner and I am switched into it
- **Given** I submit a slug that is already taken or invalid
  **When** I submit
  **Then** I see an inline validation error and can correct it
- **Given** the organization is created
  **When** I land back in `/app`
  **Then** I am guided toward creating my first Service (US-013)

## Notes
MANDATORY — plan item 2. Backend already exists
(`Foryou.Organizations.create_organization_with_owner/2`,
`POST /api/v1/organizations`, `api.createOrganization`). This story is the UI.
