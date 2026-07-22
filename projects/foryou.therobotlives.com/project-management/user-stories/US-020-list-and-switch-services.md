---
id: US-020
title: "List and switch between Services"
slug: list-and-switch-services
personas: [P-002, P-003]
epic: "Services & Branding"
priority: should-have
complexity: low
tags: [service, navigation, switcher]
---

# US-020: List and switch between Services

## User Story

**As a** user in an organization
**I want to** see all Services and switch between them
**So that** I can work on the right site's lists

## Acceptance Criteria

- **Given** my org has multiple Services
  **When** I open the Services list
  **Then** I see each Service with a quick way to open it
- **Given** I select a Service
  **When** it loads
  **Then** the app scopes lists and signups to that Service
- **Given** my org has no Services
  **When** I view the list
  **Then** I see an empty state prompting Service creation

## Notes
