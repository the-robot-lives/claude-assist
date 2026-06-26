---
id: US-997
title: "API Sandbox Environment"
slug: api-sandbox-environment
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: high
tags: [api, developer, sandbox, testing]
---

# US-997: API Sandbox Environment

## User Story

**As a** Creator
**I want to** access a sandboxed version of the Flywheel API that operates against a test copy of my data
**So that** I can develop and test integrations without affecting my live account or real followers

## Acceptance Criteria

- **Given** the Developer Portal
  **When** I create a Sandbox API key
  **Then** all requests made with that key operate against a seeded test dataset that mirrors my account structure but contains no real user data

- **Given** the sandbox environment
  **When** I perform a write operation (e.g., publish a post)
  **Then** the post appears only in the sandbox dataset and is never visible to any real Flywheel users

- **Given** the sandbox environment
  **When** I call an analytics endpoint
  **Then** I receive realistic synthetic data that exercises all response fields, enabling schema validation without real traffic

## Notes
Sandbox environment is rate-limited independently from production. Sandbox data is reset weekly. Sandbox is available to all accounts with at least one production API key.
