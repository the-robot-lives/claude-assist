---
id: US-982
title: "Access Interactive API Documentation"
slug: access-interactive-api-documentation
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [api, developer, documentation, portal]
---

# US-982: Access Interactive API Documentation

## User Story

**As a** Creator
**I want to** browse interactive API documentation with live try-it-out functionality
**So that** I can learn the API and test calls without writing code first.

## Acceptance Criteria

- **Given** the Developer Portal
  **When** I navigate to the API Docs section
  **Then** I see all endpoints organized by resource (posts, analytics, mutuals, webhooks) with request/response schemas and example payloads.

- **Given** an API Docs endpoint entry
  **When** I click "Try it out" and provide my API key
  **Then** I can execute a real API call and see the live response rendered inline.

## Notes
API docs are generated from OpenAPI 3.1 spec. The spec file is downloadable for import into tools like Postman or Insomnia.
