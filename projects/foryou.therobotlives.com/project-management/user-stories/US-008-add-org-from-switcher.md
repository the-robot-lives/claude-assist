---
id: US-008
title: "Add a new organization from the switcher"
slug: add-org-from-switcher
personas: [P-002]
epic: "Onboarding & Auth"
priority: should-have
complexity: low
tags: [org, switcher, create-org]
---

# US-008: Add a new organization from the switcher

## User Story

**As a** user with at least one organization
**I want to** create another org directly from the org switcher
**So that** I can manage multiple sites/products separately

## Acceptance Criteria

- **Given** the org switcher is open
  **When** I click "+ New org"
  **Then** I am taken to the create-organization flow (US-006)
- **Given** I create the new org from the switcher
  **When** creation succeeds
  **Then** I am switched into the new org
- **Given** creation is cancelled
  **When** I return
  **Then** my previously active org remains selected

## Notes
