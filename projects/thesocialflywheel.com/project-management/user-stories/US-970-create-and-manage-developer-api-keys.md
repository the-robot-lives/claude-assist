---
id: US-970
title: "Create and Manage Developer API Keys"
slug: create-and-manage-developer-api-keys
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [api, developer, keys, security]
---

# US-970: Create and Manage Developer API Keys

## User Story

**As a** Creator
**I want to** generate, view, rotate, and revoke my personal API keys in my account settings
**So that** I can securely integrate Flywheel with external tools without sharing my password

## Acceptance Criteria

- **Given** the Developer Settings page
  **When** I click "Create API Key"
  **Then** I provide a label and select scopes, and a new key is generated and shown once in full (never retrievable again after leaving the page)

- **Given** an existing API key
  **When** I click "Revoke"
  **Then** the key is immediately invalidated and any subsequent requests using it receive a 401 response

- **Given** an API key older than 90 days
  **When** I view the key list
  **Then** it is highlighted with a "rotate recommended" badge

## Notes
Users may hold up to 10 active API keys simultaneously. Each key stores creation date, last-used timestamp, and assigned scopes.
