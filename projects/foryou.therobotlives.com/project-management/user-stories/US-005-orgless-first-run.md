---
id: US-005
title: "See a first-run path when I have no organization"
slug: orgless-first-run
personas: [P-002]
epic: "Onboarding & Auth"
priority: must-have
complexity: low
tags: [onboarding, org, empty-state, first-run]
---

# US-005: See a first-run path when I have no organization

## User Story

**As an** authenticated user who belongs to no organization
**I want to** see an obvious next step on `/app`
**So that** I am not stranded on an empty screen

## Acceptance Criteria

- **Given** I am signed in and belong to zero organizations
  **When** I land on `/app`
  **Then** I see an explanatory empty state with a primary "Create organization" call to action
- **Given** the orgless empty state
  **When** I click the CTA
  **Then** I am taken to the create-organization flow (US-006)
- **Given** I belong to at least one organization
  **When** I land on `/app`
  **Then** the orgless CTA is not shown

## Notes
Plan item 2 (UX gap). Pairs with US-006.
