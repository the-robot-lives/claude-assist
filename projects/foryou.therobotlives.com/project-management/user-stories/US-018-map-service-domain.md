---
id: US-018
title: "Map a Service to a site domain"
slug: map-service-domain
personas: [P-003]
epic: "Services & Branding"
priority: should-have
complexity: medium
tags: [service, domain, cors, mapping]
---

# US-018: Map a Service to a site domain

## User Story

**As a** site owner
**I want to** associate a Service with the site domain it serves
**So that** signups and CORS are scoped to the right origin

## Acceptance Criteria

- **Given** I configure a Service
  **When** I add an allowed site domain/origin
  **Then** that origin is permitted for cross-origin signup submissions
- **Given** I add an invalid domain
  **When** I save
  **Then** I see a validation error
- **Given** a domain is mapped
  **When** the public endpoint receives a request from it
  **Then** CORS allows the request (see US-096)

## Notes
Coordinates with CORS configuration (US-096).
