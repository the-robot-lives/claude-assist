---
id: US-969
title: "Access Public Read API for Own Data"
slug: access-public-read-api-for-own-data
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [api, analytics, developer, read-api]
---

# US-969: Access Public Read API for Own Data

## User Story

**As a** Creator
**I want to** access a REST API endpoint to programmatically read my own post metrics and reach statistics
**So that** I can build custom dashboards or integrate my data into third-party tools

## Acceptance Criteria

- **Given** a valid API key with the read:analytics scope
  **When** I call GET /v1/me/analytics/posts
  **Then** I receive a paginated JSON response with per-post metrics including impressions, reactions, replies, and degree breakdowns

- **Given** an API key without the read:analytics scope
  **When** I call the analytics endpoint
  **Then** I receive a 403 response with a clear error message indicating the missing scope

- **Given** a valid request
  **When** the response is returned
  **Then** audience composition fields contain only aggregate data with cohort-size enforcement applied server-side

## Notes
API is versioned under /v1/. Pagination uses cursor-based navigation. Rate limits apply (see US-981).
