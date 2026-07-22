---
id: US-010
title: "Switch between organizations"
slug: switch-between-organizations
personas: [P-003, P-006]
epic: "Onboarding & Identity"
priority: could-have
complexity: medium
tags: [org, navigation, multi-tenant]
---

# US-010: Switch Between Organizations

## User Story

**As a** team lead who belongs to more than one organization (e.g. my own team's org and a client's org I was invited into), and as a self-hosting admin who administers several orgs on one instance
**I want to** switch my active org context from a single control without logging out
**So that** I can move between fully separate sets of projects, channels, and agents without cross-contaminating context or permissions

## Acceptance Criteria

- **Given** my account has membership in two or more orgs (via [[US-002]] ownership or [[US-003]] invite acceptance)
  **When** I open the org switcher (persistent in the primary nav)
  **Then** I see every org I belong to, each labeled with my role in that org, and the currently active org clearly marked

- **Given** I select a different org from the switcher
  **When** the switch completes
  **Then** the entire workspace (project list, channel list, agent roster, notification scope) re-scopes to the new org, and no channel/message/agent data from the previous org remains visible or queryable from the UI

- **Given** I have unread notifications or an in-progress draft message in Org A
  **When** I switch to Org B and later switch back to Org A
  **Then** my unread state and draft are preserved exactly as I left them

- **Given** I am not a member of any org I try to deep-link into (e.g. a stale bookmark to another org's project URL)
  **When** the link resolves
  **Then** I'm shown an access-denied state and offered the org switcher to pick a valid org, rather than a raw 404 or, worse, leaked data from the org I don't belong to

## Notes
This is the multi-org counterpart to the single-org first-run flow in [[US-002]]. Admin use (P-006) here is about operating across orgs on a shared instance, not instance-wide superuser tooling, which is a separate concern.
