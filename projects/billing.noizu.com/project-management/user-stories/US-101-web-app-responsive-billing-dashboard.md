---
id: US-101
title: "Web app responsive billing dashboard"
slug: web-app-responsive-billing-dashboard
personas: [P-001, P-002, P-007]
epic: "Cross-Platform Apps"
priority: must-have
complexity: medium
tags: [web, dashboard, responsive]
---

# US-101: Web app responsive billing dashboard

## User Story

**As a** billing operator  
**I want to** use the core receivables dashboard in the web app across desktop, tablet, and mobile widths  
**So that** billing status remains readable wherever I open the browser

## Acceptance Criteria

- **Given** invoices, customers, and payments exist  
  **When** I open the dashboard at common desktop, tablet, and phone widths  
  **Then** the layout preserves primary metrics, filters, and next actions without horizontal scrolling or overlapping controls

## Notes
The web app remains the canonical full-function surface. Mobile web may support review and light actions, but native iOS and Android apps own push-first approval flows.
