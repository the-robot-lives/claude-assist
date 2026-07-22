---
id: US-015
title: "View a Service overview"
slug: service-overview
personas: [P-003, P-004]
epic: "Services & Branding"
priority: must-have
complexity: medium
tags: [service, dashboard, overview]
---

# US-015: View a Service overview

## User Story

**As a** Service member
**I want to** see an overview of a Service
**So that** I understand its lists and signup activity at a glance

## Acceptance Criteria

- **Given** I open a Service
  **When** its overview loads
  **Then** I see its lists, signup counts, and key settings
- **Given** the Service has no lists yet
  **When** I view the overview
  **Then** I see an empty state prompting me to create a list
- **Given** I have limited permissions
  **When** I view the overview
  **Then** I see only what my role allows

## Notes
Overview is the Service landing after selection.
