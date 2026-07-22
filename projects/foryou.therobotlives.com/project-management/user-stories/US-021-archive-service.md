---
id: US-021
title: "Archive or deactivate a Service"
slug: archive-service
personas: [P-003]
epic: "Services & Branding"
priority: could-have
complexity: low
tags: [service, archive, lifecycle]
---

# US-021: Archive or deactivate a Service

## User Story

**As a** Service owner
**I want to** archive a Service I no longer use
**So that** it stops accepting signups without losing its data

## Acceptance Criteria

- **Given** I own an active Service
  **When** I archive it
  **Then** its public forms stop accepting new signups and it is hidden from active lists
- **Given** a Service is archived
  **When** I view its historical signups
  **Then** the data remains accessible read-only
- **Given** a Service is archived
  **When** I choose to restore it
  **Then** it becomes active again

## Notes
