---
id: US-088
title: "Keep the existing inquiries endpoint working"
slug: backward-compatible-inquiries-endpoint
personas: [P-003, P-001]
epic: "Inquiries & Lead Capture"
priority: should-have
complexity: medium
tags: [inquiry, backward-compat, api, migration]
---

# US-088: Keep the existing inquiries endpoint working

## User Story

**As a** site owner with existing home-page forms
**I want to** the current `POST /api/v1/inquiries` to keep working
**So that** nothing breaks during the migration

## Acceptance Criteria

- **Given** the existing inquiries endpoint
  **When** a legacy form posts to it
  **Then** the inquiry is stored exactly as before
- **Given** the endpoint receives an inquiry
  **When** it is processed
  **Then** it also writes a signup to a default foryou list so the new model stays consistent
- **Given** the dual-write
  **When** either write fails
  **Then** the failure is handled without silently losing the inquiry

## Notes
Backward-compat bridge so the existing home form keeps working (plan Chunk B).
