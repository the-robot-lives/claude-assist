---
id: US-092
title: "Webhook export events"
slug: webhook-export-events
personas: [P-006]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-092: Webhook export events

## User Story

**As a** integrated workflow user  
**I want to** send webhooks when reports are approved or exported  
**So that** automate billing pipelines

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
