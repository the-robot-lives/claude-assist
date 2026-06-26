---
id: US-105
title: "Add external social links"
slug: add-external-social-links
personas: [P-003]
epic: "Profile & Identity"
priority: should-have
complexity: low
tags: [profile, identity, links]
---

# US-105: Add External Social Links

## User Story

**As a** social connector
**I want to** add links to my other social accounts and sites on my profile
**So that** new connections can find and follow me across the platforms I use

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I add a valid URL as a labeled social link and save
  **Then** the link appears on my profile and opens the destination when clicked

- **Given** I enter a malformed or unsupported URL
  **When** I attempt to save
  **Then** I see an inline validation error and the link is not added

## Notes
Outbound links should carry safe rel attributes (noopener/noreferrer).
