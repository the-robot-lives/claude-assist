---
id: US-007
title: "Switch between organizations"
slug: switch-organization
personas: [P-002, P-003]
epic: "Onboarding & Auth"
priority: should-have
complexity: low
tags: [org, switcher, navigation]
---

# US-007: Switch between organizations

## User Story

**As a** user who belongs to more than one organization
**I want to** switch my active organization
**So that** I work in the right context

## Acceptance Criteria

- **Given** I belong to multiple organizations
  **When** I open the org switcher and pick one
  **Then** the active org updates and the app reflects that org's Services
- **Given** I switch orgs
  **When** the change applies
  **Then** my selection persists across page loads
- **Given** I belong to only one org
  **When** I open the switcher
  **Then** it shows my single org and the "+ New org" entry

## Notes
