---
id: US-102
title: "Web app deep-linkable workspace state"
slug: web-app-deep-linkable-workspace-state
personas: [P-001, P-002, P-006]
epic: "Cross-Platform Apps"
priority: must-have
complexity: medium
tags: [web, deep-links, url-state]
---

# US-102: Web app deep-linkable workspace state

## User Story

**As a** workspace member  
**I want to** share links to filtered invoices, customers, payments, and reports  
**So that** teammates land in the same billing context without manual reconstruction

## Acceptance Criteria

- **Given** I apply filters or open a specific billing record  
  **When** I copy or open the current URL  
  **Then** workspace, route, record, filters, sort, and tab state restore accurately for authorized users

## Notes
URL state must not expose secrets or raw payment data. Unauthorized users should see a safe access boundary, not leaked record metadata.
