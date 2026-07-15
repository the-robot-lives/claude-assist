---
id: US-002
title: "Create my first org and project"
slug: create-my-first-org-and-project
personas: [P-001]
epic: "Onboarding & Identity"
priority: must-have
complexity: low
tags: [first-run, org, project, setup]
---

# US-002: Create My First Org and Project

## User Story

**As a** solo staff engineer who just created my account
**I want to** be walked straight into creating an organization and a first project
**So that** I have a real workspace to launch parallel-path runs in, instead of landing on an empty dashboard

## Acceptance Criteria

- **Given** I have just verified/completed signup and have zero org memberships
  **When** the app loads
  **Then** I am routed directly into a first-run wizard that requires naming an org (slug auto-suggested, editable) before anything else is shown

- **Given** I am on the org step of the wizard
  **When** I submit an org name
  **Then** the org is created, I am set as its owner, and the wizard advances to project creation scoped to that org

- **Given** I am on the project step
  **When** I name a project and accept the default settings (default model tier, default channel)
  **Then** a project is created with a default "general" channel and I become a project member with owner-level role

- **Given** I abandon the wizard partway (close tab) after the org exists but before a project is created
  **When** I return and log in again
  **Then** I resume at the project-creation step rather than re-creating the org or being dropped into a broken empty state

## Notes
This is the second step of a chain that starts with [[US-001]]. Project creation here is intentionally minimal (no provider keys, no agents yet) — those are handled by [[US-005]] and later admin flows owned by [[P-006]].
