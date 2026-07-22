---
id: US-090
title: "Use REST API"
slug: use-rest-api
personas: [P-002, P-006]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-090: Use REST API

## User Story

**As a** integrated workflow user  
**I want to** create and query clients, projects, tasks, and intervals via API  
**So that** integrate Timely with custom systems

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
