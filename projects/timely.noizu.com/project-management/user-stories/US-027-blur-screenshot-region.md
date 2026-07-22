---
id: US-027
title: "Blur screenshot region"
slug: blur-screenshot-region
personas: [P-001, P-005, P-008]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-027: Blur screenshot region

## User Story

**As a** daily user  
**I want to** blur selected screenshot areas  
**So that** share evidence without exposing secrets

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
