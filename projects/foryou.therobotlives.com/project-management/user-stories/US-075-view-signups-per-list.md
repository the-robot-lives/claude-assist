---
id: US-075
title: "View signups to my lists across services"
slug: view-signups-per-list
personas: [P-003, P-004]
epic: "Admin Console"
priority: must-have
complexity: high
tags: [admin, signups, table, item-5]
---

# US-075: View signups to my lists across services

## User Story

**As a** site owner/admin
**I want to** view the signups for a list, for any of my services/projects
**So that** I can see who signed up and what they submitted

## Acceptance Criteria

- **Given** I open a list in the admin console
  **When** the signups table loads
  **Then** I see each signup with email, status, submitted attributes, and date
- **Given** the list declares custom attributes
  **When** the table renders
  **Then** columns reflect those declared attributes
- **Given** I have access to multiple services
  **When** I switch service/list context
  **Then** the table scopes to the selected list

## Notes
MANDATORY — plan item 5. Backed by `GET .../signups` management endpoint.
Feeds search/filter (US-076), pagination (US-077), and export (US-078).
