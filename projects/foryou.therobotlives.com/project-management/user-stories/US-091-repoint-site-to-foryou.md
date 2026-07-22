---
id: US-091
title: "Repoint a site's signup form to foryou"
slug: repoint-site-to-foryou
personas: [P-006, P-003]
epic: "listmonk Migration"
priority: must-have
complexity: medium
tags: [migration, repoint, form, widget]
---

# US-091: Repoint a site's signup form to foryou

## User Story

**As a** developer
**I want to** repoint a site's waitlist/contact form from listmonk to foryou
**So that** new signups flow into foryou

## Acceptance Criteria

- **Given** a site posting to listmonk
  **When** I repoint its form (or swap in the widget, US-046) to the foryou public endpoint
  **Then** new signups are recorded in the foryou List
- **Given** the repoint is deployed
  **When** a real signup is submitted
  **Then** it appears in foryou and not in listmonk
- **Given** the repoint fails validation or CORS
  **When** it is tested pre-launch
  **Then** issues are caught before cutover

## Notes
Old listmonk list UUIDs are recorded in the plan for each site.
