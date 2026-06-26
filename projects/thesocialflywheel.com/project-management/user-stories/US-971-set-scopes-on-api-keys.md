---
id: US-971
title: "Set Scopes on API Keys"
slug: set-scopes-on-api-keys
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [api, developer, scopes, security]
---

# US-971: Set Scopes on API Keys

## User Story

**As a** Creator
**I want to** assign specific permission scopes to each API key I create
**So that** I can grant third-party tools only the minimum access they need, limiting risk if a key is compromised.

## Acceptance Criteria

- **Given** the "Create API Key" flow
  **When** I select scopes
  **Then** I can choose from: read:analytics, read:posts, write:posts, read:profile, read:mutuals — with a plain-English description of each.

- **Given** an API key with only read:analytics scope
  **When** it is used to call a write endpoint
  **Then** the response is 403 with a message listing the missing scope.

## Notes

Scope list is versioned and documented in the developer portal. New scopes added in future API versions do not auto-grant to existing keys.
