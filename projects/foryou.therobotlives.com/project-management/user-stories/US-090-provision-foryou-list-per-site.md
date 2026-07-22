---
id: US-090
title: "Provision a foryou List per site for cutover"
slug: provision-foryou-list-per-site
personas: [P-003]
epic: "listmonk Migration"
priority: should-have
complexity: medium
tags: [migration, provisioning, terraform, list]
---

# US-090: Provision a foryou List per site for cutover

## User Story

**As a** site owner
**I want to** provision a foryou List that mirrors each site's listmonk list
**So that** the site has a destination before repointing

## Acceptance Criteria

- **Given** a site's existing listmonk list
  **When** I provision the equivalent foryou List via the TF provider (US-036)
  **Then** the List exists with the attributes the site collects
- **Given** the List is provisioned
  **When** I inspect it
  **Then** its opt-in mode matches the site's needs (waitlist vs newsletter)
- **Given** re-running provisioning
  **When** the List already exists
  **Then** it is updated idempotently, not duplicated

## Notes
Precedes repoint (US-091) for each site.
