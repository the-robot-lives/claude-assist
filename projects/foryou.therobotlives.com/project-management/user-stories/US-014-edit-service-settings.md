---
id: US-014
title: "Edit Service settings"
slug: edit-service-settings
personas: [P-004, P-003]
epic: "Services & Branding"
priority: must-have
complexity: low
tags: [service, settings, configuration]
---

# US-014: Edit Service settings

## User Story

**As a** Service editor
**I want to** edit a Service's name, slug, and description
**So that** its identity stays accurate

## Acceptance Criteria

- **Given** I have edit permission on a Service
  **When** I update its settings and save
  **Then** the changes persist and are reflected across the app
- **Given** I change the slug
  **When** I save
  **Then** existing references remain valid or are safely redirected
- **Given** I lack edit permission
  **When** I open settings
  **Then** the fields are read-only

## Notes
